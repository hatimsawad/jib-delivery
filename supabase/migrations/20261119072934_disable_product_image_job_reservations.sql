-- Block product-image job reservations at the database boundary as well as the API.
CREATE OR REPLACE FUNCTION public.jib_ai_manager_reserve_image_job(p_request_type text, p_product_id uuid DEFAULT NULL::uuid, p_title text DEFAULT NULL::text, p_description text DEFAULT NULL::text)
 RETURNS TABLE(job_id uuid, store_id uuid, product_id uuid, request_type text, title text, description text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth', 'pg_temp'
AS $function$
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

  select p.role into v_role
  from public.profiles p
  where p.id = v_uid;

  if v_role is null or v_role not in ('merchant', 'admin') then
    raise exception 'Only merchants or admins can request image generation';
  end if;

  if p_request_type = 'product' then
    raise exception 'AI product image generation is disabled until verified reference-image processing is available';
  elsif p_request_type = 'article' then
    if v_role is distinct from 'admin' then
      raise exception 'Only admins can generate article cover images';
    end if;

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

  perform pg_advisory_xact_lock(hashtext('jib_ai_manager_image_monthly_quota'));

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
    jsonb_build_object(
      'job_id', v_job_id,
      'request_type', p_request_type,
      'store_id', v_store_id,
      'product_id', v_product_id
    ),
    'acknowledged'
  );

  return query
  select v_job_id, v_store_id, v_product_id, p_request_type, v_title, v_description;
end;
$function$;

revoke all on function public.jib_ai_manager_reserve_image_job(text, uuid, text, text) from public, anon;
grant execute on function public.jib_ai_manager_reserve_image_job(text, uuid, text, text) to authenticated;