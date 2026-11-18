-- AI-generated product/article images are drafts until a human approves them.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('article-images', 'article-images', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "JIB admins can upload article images" on storage.objects;
create policy "JIB admins can upload article images"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'article-images' and (select public.is_jib_admin()));

create table if not exists public.jib_ai_manager_image_jobs (
  id uuid primary key default gen_random_uuid(),
  request_type text not null check (request_type in ('product','article')),
  store_id uuid references public.stores(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  requested_by uuid not null references auth.users(id) on delete restrict,
  title text not null,
  description text not null,
  status text not null default 'generating'
    check (status in ('generating','ready_for_review','approved','rejected','failed')),
  generated_image_url text,
  storage_bucket text,
  storage_path text,
  model text,
  estimated_cost_usd numeric(10,4),
  error_message text,
  is_ai_generated boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  constraint jib_ai_manager_image_job_product_shape_check
    check ((request_type = 'product' and store_id is not null and product_id is not null)
        or (request_type = 'article' and store_id is null and product_id is null))
);

create index if not exists jib_ai_manager_image_jobs_created_idx
  on public.jib_ai_manager_image_jobs (created_at desc);
create index if not exists jib_ai_manager_image_jobs_store_status_idx
  on public.jib_ai_manager_image_jobs (store_id, status, created_at desc);

alter table public.jib_ai_manager_image_jobs enable row level security;
revoke all on public.jib_ai_manager_image_jobs from public, anon, authenticated;
grant select on public.jib_ai_manager_image_jobs to authenticated;

drop policy if exists "JIB admins and store owners can read image jobs" on public.jib_ai_manager_image_jobs;
create policy "JIB admins and store owners can read image jobs"
  on public.jib_ai_manager_image_jobs for select to authenticated
  using (
    (select public.is_jib_admin())
    or exists (
      select 1 from public.stores s
      where s.id = store_id and s.owner_id = (select auth.uid())
    )
  );

create or replace function public.jib_ai_manager_reserve_image_job(
  p_request_type text,
  p_product_id uuid default null,
  p_title text default null,
  p_description text default null
)
returns table (
  job_id uuid,
  store_id uuid,
  product_id uuid,
  request_type text,
  title text,
  description text
)
language plpgsql
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_role text;
  v_store_id uuid;
  v_product_id uuid;
  v_title text;
  v_description text;
  v_count integer;
  v_job_id uuid;
begin
  if v_uid is null then raise exception 'Authentication required'; end if;

  select p.role into v_role from public.profiles p where p.id = v_uid;
  if v_role not in ('merchant','admin') then raise exception 'Only merchants or admins can request image generation'; end if;

  if p_request_type = 'product' then
    select pr.store_id, pr.id, pr.name, coalesce(pr.description, '')
    into v_store_id, v_product_id, v_title, v_description
    from public.products pr
    join public.stores s on s.id = pr.store_id
    where pr.id = p_product_id
      and (s.owner_id = v_uid or v_role = 'admin');

    if not found then raise exception 'Product not found or not owned by this account'; end if;
    if nullif(trim(p_description), '') is not null then
      v_description := trim(p_description);
    end if;
    if nullif(trim(v_description), '') is null then
      raise exception 'Add the dish ingredients or description before generating an image';
    end if;
  elsif p_request_type = 'article' then
    if v_role <> 'admin' then raise exception 'Only admins can generate article cover images'; end if;
    v_title := nullif(trim(p_title), '');
    v_description := nullif(trim(p_description), '');
    if v_title is null or v_description is null then
      raise exception 'Article title and summary are required';
    end if;
    v_store_id := null;
    v_product_id := null;
  else
    raise exception 'Unsupported image request type';
  end if;

  select count(*) into v_count
  from public.jib_ai_manager_image_jobs j
  where j.created_at >= date_trunc('month', now());

  if v_count >= 100 then
    raise exception 'Monthly AI image limit reached (100 requests). Try again next month.';
  end if;

  insert into public.jib_ai_manager_image_jobs (
    request_type, store_id, product_id, requested_by, title, description, status
  ) values (
    p_request_type, v_store_id, v_product_id, v_uid, v_title, v_description, 'generating'
  )
  returning id into v_job_id;

  insert into public.jib_ai_manager_events (
    fingerprint, event_type, severity, title, message, details, status
  ) values (
    'image-request:' || v_job_id::text,
    'image_generation_requested',
    'info',
    'طلب إنشاء صورة بالذكاء الاصطناعي',
    'تم استلام طلب إنشاء صورة وينتظر اكتمال التوليد والمراجعة.',
    jsonb_build_object('job_id', v_job_id, 'request_type', p_request_type, 'store_id', v_store_id, 'product_id', v_product_id),
    'acknowledged'
  );

  return query select v_job_id, v_store_id, v_product_id, p_request_type, v_title, v_description;
end;
$function$;

create or replace function public.jib_ai_manager_finish_image_job(
  p_job_id uuid,
  p_image_url text,
  p_storage_bucket text,
  p_storage_path text,
  p_model text,
  p_estimated_cost_usd numeric default 0.0200
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
  select * into v_job from public.jib_ai_manager_image_jobs where id = p_job_id for update;
  if not found then raise exception 'Image job not found'; end if;
  if v_job.requested_by <> v_uid
     and not (select public.is_jib_admin())
     and not exists (select 1 from public.stores s where s.id = v_job.store_id and s.owner_id = v_uid) then
    raise exception 'Not authorized to finish this image job';
  end if;
  if v_job.status <> 'generating' then raise exception 'Image job is not generating'; end if;
  if p_image_url is null or p_storage_bucket not in ('product-images','article-images') or p_storage_path is null then
    raise exception 'Generated image storage details are incomplete';
  end if;

  update public.jib_ai_manager_image_jobs
  set status = 'ready_for_review',
      generated_image_url = p_image_url,
      storage_bucket = p_storage_bucket,
      storage_path = p_storage_path,
      model = p_model,
      estimated_cost_usd = greatest(0, coalesce(p_estimated_cost_usd, 0)),
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

create or replace function public.jib_ai_manager_fail_image_job(p_job_id uuid, p_error_message text)
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
  select * into v_job from public.jib_ai_manager_image_jobs where id = p_job_id for update;
  if not found then raise exception 'Image job not found'; end if;
  if v_job.requested_by <> v_uid
     and not (select public.is_jib_admin())
     and not exists (select 1 from public.stores s where s.id = v_job.store_id and s.owner_id = v_uid) then
    raise exception 'Not authorized to fail this image job';
  end if;
  update public.jib_ai_manager_image_jobs
  set status = 'failed', error_message = left(coalesce(p_error_message, 'Image generation failed'), 500), updated_at = now()
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
    if v_role <> 'admin' then raise exception 'Only admins can review article images'; end if;
  elsif v_role <> 'admin' and not exists (
    select 1 from public.stores s where s.id = v_job.store_id and s.owner_id = v_uid
  ) then
    raise exception 'Not authorized to review this product image';
  end if;

  if v_job.status <> 'ready_for_review' then raise exception 'Image is not ready for review'; end if;

  if p_approve and v_job.request_type = 'product' then
    update public.products
    set image_url = v_job.generated_image_url, updated_at = now()
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

revoke all on function public.jib_ai_manager_reserve_image_job(text,uuid,text,text) from public, anon;
revoke all on function public.jib_ai_manager_finish_image_job(uuid,text,text,text,text,numeric) from public, anon;
revoke all on function public.jib_ai_manager_fail_image_job(uuid,text) from public, anon;
revoke all on function public.jib_ai_manager_review_image_job(uuid,boolean) from public, anon;
grant execute on function public.jib_ai_manager_reserve_image_job(text,uuid,text,text) to authenticated;
grant execute on function public.jib_ai_manager_finish_image_job(uuid,text,text,text,text,numeric) to authenticated;
grant execute on function public.jib_ai_manager_fail_image_job(uuid,text) to authenticated;
grant execute on function public.jib_ai_manager_review_image_job(uuid,boolean) to authenticated;

comment on table public.jib_ai_manager_image_jobs is
  'AI-generated product and article image drafts. Images are not published until a merchant/admin explicitly approves them. Monthly request cap: 100.';
