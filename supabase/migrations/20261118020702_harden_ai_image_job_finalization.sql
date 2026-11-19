-- Harden AI image finalization: only the authenticated uploader can finalize
-- an owned storage object at the exact job-specific path. Failed jobs cannot
-- overwrite a completed or reviewed job.
create or replace function public.jib_ai_manager_finish_image_job(
  p_job_id uuid,
  p_image_url text,
  p_storage_bucket text,
  p_storage_path text,
  p_model text,
  p_estimated_cost_usd numeric default 0.009
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_job public.jib_ai_manager_image_jobs%rowtype;
  v_expected_path_prefix text;
  v_expected_url text;
begin
  if v_uid is null then raise exception 'Authentication required'; end if;

  select * into v_job
  from public.jib_ai_manager_image_jobs
  where id = p_job_id
  for update;

  if not found then raise exception 'Image job not found'; end if;
  if v_job.status <> 'generating' then raise exception 'Image job is not generating'; end if;

  if v_job.requested_by <> v_uid
     and not (select public.is_jib_admin())
     and not exists (
       select 1 from public.stores s
       where s.id = v_job.store_id and s.owner_id = v_uid
     ) then
    raise exception 'Not authorized to finish this image job';
  end if;

  if p_model is distinct from 'bfl/flux-3-image-klein'
     or p_estimated_cost_usd is null
     or p_estimated_cost_usd < 0
     or p_estimated_cost_usd > 0.009 then
    raise exception 'Invalid image model or estimated cost';
  end if;

  if v_job.request_type = 'product' then
    if p_storage_bucket is distinct from 'product-images'
       or p_storage_path !~ (
         '^' || v_job.store_id::text || '/ai-drafts/' || p_job_id::text || '\.(png|jpg|webp)$'
       ) then
      raise exception 'Product image path does not match this job';
    end if;
  elsif v_job.request_type = 'article' then
    if not (select public.is_jib_admin()) then
      raise exception 'Only admins can finalize article images';
    end if;
    if p_storage_bucket is distinct from 'article-images'
       or p_storage_path !~ (
         '^articles/' || p_job_id::text || '\.(png|jpg|webp)$'
       ) then
      raise exception 'Article image path does not match this job';
    end if;
  else
    raise exception 'Unsupported image request type';
  end if;

  if not exists (
    select 1
    from storage.objects o
    where o.bucket_id = p_storage_bucket
      and o.name = p_storage_path
      and o.owner_id = v_uid
  ) then
    raise exception 'Uploaded image is missing or is not owned by this account';
  end if;

  v_expected_url := 'https://emvleaghjsmzjmzgguvu.supabase.co/storage/v1/object/public/'
    || p_storage_bucket || '/' || p_storage_path;

  if p_image_url is distinct from v_expected_url then
    raise exception 'Image URL does not match the uploaded storage object';
  end if;

  update public.jib_ai_manager_image_jobs
  set status = 'ready_for_review',
      generated_image_url = p_image_url,
      storage_bucket = p_storage_bucket,
      storage_path = p_storage_path,
      model = p_model,
      estimated_cost_usd = p_estimated_cost_usd,
      error_message = null,
      updated_at = now()
  where id = p_job_id;

  insert into public.jib_ai_manager_events (
    fingerprint, event_type, severity, title, message, details, status
  ) values (
    'image-ready:' || p_job_id::text,
    'image_generation_ready',
    'info',
    'الصورة جاهزة للمراجعة',
    'تم إنشاء الصورة وهي بانتظار موافقة التاجر أو الإدارة قبل النشر.',
    jsonb_build_object('job_id', p_job_id, 'request_type', v_job.request_type, 'model', p_model),
    'acknowledged'
  );

  return true;
end;
$function$;

create or replace function public.jib_ai_manager_fail_image_job(
  p_job_id uuid,
  p_error_message text
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_job public.jib_ai_manager_image_jobs%rowtype;
begin
  if v_uid is null then raise exception 'Authentication required'; end if;

  select * into v_job
  from public.jib_ai_manager_image_jobs
  where id = p_job_id
  for update;

  if not found then raise exception 'Image job not found'; end if;

  if v_job.requested_by <> v_uid
     and not (select public.is_jib_admin())
     and not exists (
       select 1 from public.stores s
       where s.id = v_job.store_id and s.owner_id = v_uid
     ) then
    raise exception 'Not authorized to fail this image job';
  end if;

  if v_job.status <> 'generating' then
    raise exception 'Only a generating image job can be marked failed';
  end if;

  update public.jib_ai_manager_image_jobs
  set status = 'failed',
      error_message = left(coalesce(p_error_message, 'Image generation failed'), 500),
      updated_at = now()
  where id = p_job_id;

  insert into public.jib_ai_manager_events (
    fingerprint, event_type, severity, title, message, details, status
  ) values (
    'image-failed:' || p_job_id::text,
    'image_generation_failed',
    'warning',
    'تعذر إنشاء الصورة',
    'فشلت عملية إنشاء صورة بالذكاء الاصطناعي.',
    jsonb_build_object('job_id', p_job_id, 'request_type', v_job.request_type),
    'acknowledged'
  );

  return true;
end;
$function$;

revoke all on function public.jib_ai_manager_finish_image_job(uuid,text,text,text,text,numeric) from public, anon;
revoke all on function public.jib_ai_manager_fail_image_job(uuid,text) from public, anon;
grant execute on function public.jib_ai_manager_finish_image_job(uuid,text,text,text,text,numeric) to authenticated;
grant execute on function public.jib_ai_manager_fail_image_job(uuid,text) to authenticated;
