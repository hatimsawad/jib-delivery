-- Explicitly label AI-generated product photos so the customer app can disclose them.
alter table public.products
  add column if not exists image_is_ai_generated boolean not null default false;

create or replace function public.jib_ai_manager_review_image_job(p_job_id uuid, p_approve boolean)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_role text;
  v_job public.jib_ai_manager_image_jobs%rowtype;
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  select p.role into v_role from public.profiles p where p.id = v_uid;
  select * into v_job from public.jib_ai_manager_image_jobs where id = p_job_id for update;
  if not found then raise exception 'Image job not found'; end if;

  if v_job.request_type = 'article' then
    if v_role is distinct from 'admin' then raise exception 'Only admins can review article images'; end if;
  elsif v_role <> 'admin' and not exists (
    select 1 from public.stores s where s.id = v_job.store_id and s.owner_id = v_uid
  ) then
    raise exception 'Not authorized to review this product image';
  end if;

  if v_job.status <> 'ready_for_review' then raise exception 'Image is not ready for review'; end if;

  if p_approve and v_job.request_type = 'product' then
    update public.products
    set image_url = v_job.generated_image_url,
        image_is_ai_generated = true,
        updated_at = now()
    where id = v_job.product_id and store_id = v_job.store_id;
    if not found then raise exception 'Product no longer exists'; end if;
  end if;

  update public.jib_ai_manager_image_jobs
  set status = case when p_approve then 'approved' else 'rejected' end,
      reviewed_by = v_uid,
      reviewed_at = now(),
      updated_at = now()
  where id = p_job_id;

  insert into public.jib_ai_manager_events (
    fingerprint, event_type, severity, title, message, details, status
  ) values (
    'image-review:' || p_job_id::text || ':' || case when p_approve then 'approved' else 'rejected' end,
    'image_generation_reviewed',
    'info',
    case when p_approve then 'تم اعتماد الصورة' else 'تم رفض الصورة' end,
    case when p_approve then 'تم اعتماد الصورة للنشر.' else 'تم رفض الصورة المولدة ولم تُنشر.' end,
    jsonb_build_object('job_id', p_job_id, 'request_type', v_job.request_type, 'approved', p_approve),
    'acknowledged'
  );
  return true;
end;
$function$;
