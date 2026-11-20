-- Automatically assign a newly accepted order to the nearest approved courier
-- who explicitly enabled location sharing and sent a fresh GPS heartbeat.
create or replace function public.jib_dispatch_order(p_order_id uuid)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $$
declare
  v_order public.orders%rowtype;
  v_store_lat double precision;
  v_store_lon double precision;
  v_courier_id uuid;
  v_rows integer;
begin
  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then return false; end if;
  if v_order.courier_id is not null then return true; end if;
  if v_order.status not in ('accepted', 'preparing', 'ready_for_pickup') then return false; end if;
  if v_order.fulfillment_mode_snapshot <> 'courier_places_order' then return false; end if;

  select s.latitude, s.longitude
  into v_store_lat, v_store_lon
  from public.stores s
  where s.id = v_order.store_id;

  select cp.user_id
  into v_courier_id
  from public.courier_profiles cp
  join public.profiles p on p.id = cp.user_id and p.role = 'courier'
  join public.courier_location_tracking t
    on t.courier_id = cp.user_id
   and t.tracking_enabled = true
   and t.last_location_at >= now() - interval '60 seconds'
  join lateral (
    select e.latitude, e.longitude, e.recorded_at
    from public.courier_location_events e
    where e.courier_id = cp.user_id
    order by e.recorded_at desc
    limit 1
  ) loc on loc.recorded_at >= now() - interval '60 seconds'
  where cp.is_active = true
    and not exists (
      select 1 from public.orders active_order
      where active_order.courier_id = cp.user_id
        and active_order.status in ('accepted', 'preparing', 'ready_for_pickup', 'picked_up', 'delivering')
    )
  order by
    case
      when v_store_lat is not null and v_store_lon is not null then
        6371000 * 2 * asin(sqrt(
          power(sin(radians(loc.latitude - v_store_lat) / 2), 2)
          + cos(radians(v_store_lat)) * cos(radians(loc.latitude))
            * power(sin(radians(loc.longitude - v_store_lon) / 2), 2)
        ))
      else 0
    end asc,
    t.last_location_at desc
  limit 1
  for update of cp skip locked;

  if v_courier_id is null then
    insert into public.jib_ai_manager_events (
      fingerprint, event_type, severity, title, message, details, status,
      first_seen_at, last_seen_at, occurrence_count
    ) values (
      'courier-assignment-pending:' || p_order_id::text,
      'courier_assignment_pending',
      'warning',
      'طلب بانتظار إسناد مندوب',
      'تم قبول الطلب ولم يتوفر مندوب معتمد يشارك موقعه حالياً. سيُعاد فحص الإسناد تلقائياً.',
      jsonb_build_object('order_id', p_order_id, 'store_id', v_order.store_id),
      'open', now(), now(), 1
    )
    on conflict (fingerprint) do update
      set last_seen_at = now(),
          occurrence_count = public.jib_ai_manager_events.occurrence_count + 1,
          status = 'open',
          resolved_at = null;
    return false;
  end if;

  update public.orders
  set courier_id = v_courier_id, updated_at = now()
  where id = p_order_id and courier_id is null;
  get diagnostics v_rows = row_count;
  if v_rows <> 1 then return false; end if;

  insert into public.order_events(order_id, actor_id, status, note)
  values (p_order_id, null, 'courier_assigned',
          'Automatically assigned to the nearest approved courier with active consent and a fresh GPS location.');

  update public.jib_ai_manager_events
  set status = 'resolved', resolved_at = now(), last_seen_at = now()
  where fingerprint = 'courier-assignment-pending:' || p_order_id::text
    and status <> 'resolved';

  return true;
end;
$$;

create or replace function public.jib_dispatch_unassigned_orders()
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $$
declare
  v_order_id uuid;
  v_assigned integer := 0;
begin
  for v_order_id in
    select o.id
    from public.orders o
    where o.courier_id is null
      and o.status in ('accepted', 'preparing', 'ready_for_pickup')
      and o.fulfillment_mode_snapshot = 'courier_places_order'
    order by o.created_at asc
    limit 100
  loop
    if public.jib_dispatch_order(v_order_id) then
      v_assigned := v_assigned + 1;
    end if;
  end loop;
  return v_assigned;
end;
$$;

-- Merchant acceptance triggers immediate dispatch in the same transaction.
create or replace function public.merchant_update_order_status(
  p_order_id uuid,
  p_new_status text
)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $function$
declare
  v_uid uuid := auth.uid();
  v_old_status text;
begin
  if v_uid is null then raise exception 'يجب تسجيل الدخول أولاً'; end if;
  if p_new_status not in ('accepted','rejected','preparing','ready_for_pickup') then
    raise exception 'حالة الطلب غير صالحة';
  end if;

  select o.status into v_old_status
  from public.orders o
  join public.stores s on s.id = o.store_id
  where o.id = p_order_id and s.owner_id = v_uid
  for update of o;

  if not found then raise exception 'الطلب غير موجود أو لا تملك صلاحية تعديله'; end if;

  if not (
    (v_old_status = 'pending' and p_new_status in ('accepted','rejected')) or
    (v_old_status = 'accepted' and p_new_status = 'preparing') or
    (v_old_status = 'preparing' and p_new_status = 'ready_for_pickup')
  ) then
    raise exception 'لا يمكن نقل الطلب من % إلى %', v_old_status, p_new_status;
  end if;

  update public.orders set status = p_new_status, updated_at = now() where id = p_order_id;
  insert into public.order_events(order_id, actor_id, status, note)
  values (p_order_id, v_uid, p_new_status, 'Merchant updated order status');

  if p_new_status in ('accepted','preparing','ready_for_pickup') then
    perform public.jib_dispatch_order(p_order_id);
  end if;
end;
$function$;

-- Only couriers who explicitly consented and have a fresh GPS heartbeat can claim
-- an unassigned ready order. Auto-assigned couriers do not need to claim it again.
create or replace function public.claim_delivery_order(p_order_id uuid)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_rows integer;
begin
  if v_uid is null then raise exception 'يجب تسجيل الدخول أولاً'; end if;
  if not exists (
    select 1 from public.profiles p
    join public.courier_profiles cp on cp.user_id = p.id
    where p.id = v_uid and p.role = 'courier' and cp.is_active = true
  ) then
    raise exception 'حساب المندوب غير معتمد أو غير نشط';
  end if;
  if not exists (
    select 1 from public.courier_location_tracking t
    where t.courier_id = v_uid and t.tracking_enabled = true
      and t.last_location_at >= now() - interval '60 seconds'
  ) then
    raise exception 'يجب تفعيل مشاركة الموقع والحصول على تحديث GPS حديث قبل استلام التوصيلة';
  end if;

  update public.orders set courier_id = v_uid, updated_at = now()
  where id = p_order_id and status = 'ready_for_pickup' and courier_id is null;
  get diagnostics v_rows = row_count;
  if v_rows <> 1 then raise exception 'الطلب لم يعد متاحاً لمندوب آخر'; end if;

  insert into public.order_events(order_id, actor_id, status, note)
  values (p_order_id, v_uid, 'courier_assigned', 'Courier claimed delivery');
  return true;
end;
$function$;

-- Do not advertise unassigned jobs to couriers without active, fresh location sharing.
create or replace function public.courier_dashboard()
returns table(
  order_id uuid,
  status text,
  total_mad numeric,
  delivery_fee_mad numeric,
  customer_note text,
  created_at timestamptz,
  store_name text,
  store_address text,
  delivery_address text
)
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $function$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'يجب تسجيل الدخول أولاً'; end if;
  if not exists (
    select 1 from public.profiles p
    join public.courier_profiles cp on cp.user_id = p.id
    where p.id = v_uid and p.role = 'courier' and cp.is_active = true
  ) then
    raise exception 'حساب المندوب ينتظر اعتماد الإدارة';
  end if;

  return query
  select
    o.id,
    o.status,
    o.total_mad,
    o.delivery_fee_mad,
    case when o.courier_id = v_uid then o.customer_note else null end,
    o.created_at,
    s.name,
    s.address_text,
    case when o.courier_id = v_uid then a.address_text else null end
  from public.orders o
  join public.stores s on s.id = o.store_id
  left join public.addresses a on a.id = o.address_id
  where o.courier_id = v_uid
     or (
       o.courier_id is null
       and o.status = 'ready_for_pickup'
       and exists (
         select 1 from public.courier_location_tracking t
         where t.courier_id = v_uid and t.tracking_enabled = true
           and t.last_location_at >= now() - interval '60 seconds'
       )
     )
  order by o.created_at asc;
end;
$function$;

revoke all on function public.jib_dispatch_order(uuid) from public, anon, authenticated;
revoke all on function public.jib_dispatch_unassigned_orders() from public, anon, authenticated;
revoke all on function public.merchant_update_order_status(uuid, text) from public, anon;
grant execute on function public.merchant_update_order_status(uuid, text) to authenticated;
revoke all on function public.claim_delivery_order(uuid) from public, anon;
grant execute on function public.claim_delivery_order(uuid) to authenticated;
revoke all on function public.courier_dashboard() from public, anon;
grant execute on function public.courier_dashboard() to authenticated;

do $$
declare v_job_id bigint;
begin
  select jobid into v_job_id from cron.job where jobname = 'jib-dispatch-unassigned-orders';
  if v_job_id is not null then perform cron.unschedule(v_job_id); end if;
  perform cron.schedule('jib-dispatch-unassigned-orders', '* * * * *',
    'select public.jib_dispatch_unassigned_orders()');
end;
$$;
