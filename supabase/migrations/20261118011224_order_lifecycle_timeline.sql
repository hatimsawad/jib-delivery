-- Record courier assignment as its own lifecycle stage and expose an RLS-safe order timeline.
update public.order_events
set status = 'courier_assigned'
where note = 'Courier claimed delivery'
  and status = 'ready_for_pickup';

create or replace function public.claim_delivery_order(p_order_id uuid)
returns boolean
language plpgsql
security definer
set search_path to 'pg_catalog', 'public', 'auth'
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_rows integer;
begin
  if v_uid is null then
    raise exception 'يجب تسجيل الدخول أولاً';
  end if;

  if not exists (
    select 1 from public.profiles p
    join public.courier_profiles cp on cp.user_id = p.id
    where p.id = v_uid and p.role = 'courier' and cp.is_active = true
  ) then
    raise exception 'حساب المندوب غير معتمد أو غير نشط';
  end if;

  update public.orders
  set courier_id = v_uid, updated_at = now()
  where id = p_order_id
    and status = 'ready_for_pickup'
    and courier_id is null;

  get diagnostics v_rows = row_count;
  if v_rows <> 1 then
    raise exception 'الطلب لم يعد متاحاً لمندوب آخر';
  end if;

  insert into public.order_events(order_id, actor_id, status, note)
  values (p_order_id, v_uid, 'courier_assigned', 'Courier claimed delivery');

  return true;
end;
$function$;

create or replace function public.jib_order_timeline(p_order_id uuid)
returns table (
  order_id uuid,
  current_stage text,
  order_placed_at timestamptz,
  merchant_accepted_at timestamptz,
  preparation_started_at timestamptz,
  ready_for_pickup_at timestamptz,
  courier_assigned_at timestamptz,
  picked_up_at timestamptz,
  delivering_at timestamptz,
  delivered_at timestamptz,
  elapsed_seconds bigint,
  expected_remaining_seconds bigint,
  eta_confidence text,
  estimated_delivery_at timestamptz
)
language sql
stable
security invoker
set search_path to 'pg_catalog', 'public', 'auth'
as $function$
with target as (
  select o.id, o.status as order_status
  from public.orders o
  where o.id = p_order_id
),
timeline as (
  select
    min(e.created_at) filter (where e.status = 'pending') as order_placed_at,
    min(e.created_at) filter (where e.status = 'accepted') as merchant_accepted_at,
    min(e.created_at) filter (where e.status = 'preparing') as preparation_started_at,
    min(e.created_at) filter (where e.status = 'ready_for_pickup') as ready_for_pickup_at,
    min(e.created_at) filter (where e.status = 'courier_assigned') as courier_assigned_at,
    min(e.created_at) filter (where e.status = 'picked_up') as picked_up_at,
    min(e.created_at) filter (where e.status = 'delivering') as delivering_at,
    min(e.created_at) filter (where e.status = 'delivered') as delivered_at
  from public.order_events e
  where e.order_id = p_order_id
),
historical_order_stages as (
  select
    e.order_id,
    min(e.created_at) filter (where e.status = 'pending') as placed_at,
    min(e.created_at) filter (where e.status = 'accepted') as accepted_at,
    min(e.created_at) filter (where e.status = 'preparing') as preparing_at,
    min(e.created_at) filter (where e.status = 'ready_for_pickup') as ready_at,
    min(e.created_at) filter (where e.status = 'courier_assigned') as assigned_at,
    min(e.created_at) filter (where e.status = 'picked_up') as pickup_at,
    min(e.created_at) filter (where e.status = 'delivered') as delivered_at
  from public.order_events e
  group by e.order_id
),
historical_durations as (
  select
    count(*) filter (
      where placed_at is not null and accepted_at is not null
        and preparing_at is not null and ready_at is not null
        and assigned_at is not null and pickup_at is not null and delivered_at is not null
    ) as sample_count,
    percentile_cont(0.5) within group (order by extract(epoch from accepted_at - placed_at))
      filter (where placed_at is not null and accepted_at is not null) as acceptance_seconds,
    percentile_cont(0.5) within group (order by extract(epoch from ready_at - preparing_at))
      filter (where preparing_at is not null and ready_at is not null) as preparation_seconds,
    percentile_cont(0.5) within group (order by extract(epoch from assigned_at - ready_at))
      filter (where ready_at is not null and assigned_at is not null) as matching_seconds,
    percentile_cont(0.5) within group (order by extract(epoch from pickup_at - assigned_at))
      filter (where assigned_at is not null and pickup_at is not null) as pickup_seconds,
    percentile_cont(0.5) within group (order by extract(epoch from delivered_at - pickup_at))
      filter (where pickup_at is not null and delivered_at is not null) as delivery_seconds
  from historical_order_stages
  where delivered_at is not null
),
durations as (
  select
    coalesce(case when sample_count >= 5 then acceptance_seconds end, 480)::bigint as acceptance_seconds,
    coalesce(case when sample_count >= 5 then preparation_seconds end, 1200)::bigint as preparation_seconds,
    coalesce(case when sample_count >= 5 then matching_seconds end, 480)::bigint as matching_seconds,
    coalesce(case when sample_count >= 5 then pickup_seconds end, 300)::bigint as pickup_seconds,
    coalesce(case when sample_count >= 5 then delivery_seconds end, 1200)::bigint as delivery_seconds,
    (sample_count >= 5) as historical_eta
  from historical_durations
),
combined as (
  select
    t.id as order_id,
    case
      when t.order_status in ('cancelled','rejected') then t.order_status
      when tl.delivered_at is not null then 'delivered'
      when tl.delivering_at is not null then 'delivering'
      when tl.picked_up_at is not null then 'picked_up'
      when tl.courier_assigned_at is not null then 'courier_assigned'
      when tl.ready_for_pickup_at is not null then 'ready_for_pickup'
      when tl.preparation_started_at is not null then 'preparing'
      when tl.merchant_accepted_at is not null then 'accepted'
      else 'pending'
    end as stage,
    tl.*,
    d.*,
    greatest(0, extract(epoch from now() - case
      when t.order_status in ('cancelled','rejected') then coalesce(tl.delivered_at, tl.order_placed_at, now())
      when tl.delivered_at is not null then tl.delivered_at
      when tl.delivering_at is not null or tl.picked_up_at is not null then coalesce(tl.picked_up_at, tl.delivering_at)
      when tl.courier_assigned_at is not null then tl.courier_assigned_at
      when tl.ready_for_pickup_at is not null then tl.ready_for_pickup_at
      when tl.preparation_started_at is not null then tl.preparation_started_at
      when tl.merchant_accepted_at is not null then tl.merchant_accepted_at
      else tl.order_placed_at
    end))::bigint as current_stage_elapsed
  from target t
  cross join timeline tl
  cross join durations d
),
remaining as (
  select
    c.*,
    case c.stage
      when 'pending' then greatest(0, c.acceptance_seconds - c.current_stage_elapsed)
        + c.preparation_seconds + c.matching_seconds + c.pickup_seconds + c.delivery_seconds
      when 'accepted' then c.preparation_seconds + c.matching_seconds + c.pickup_seconds + c.delivery_seconds
      when 'preparing' then greatest(0, c.preparation_seconds - c.current_stage_elapsed)
        + c.matching_seconds + c.pickup_seconds + c.delivery_seconds
      when 'ready_for_pickup' then greatest(0, c.matching_seconds - c.current_stage_elapsed)
        + c.pickup_seconds + c.delivery_seconds
      when 'courier_assigned' then greatest(0, c.pickup_seconds - c.current_stage_elapsed)
        + c.delivery_seconds
      when 'picked_up' then greatest(0, c.delivery_seconds - c.current_stage_elapsed)
      when 'delivering' then greatest(0, c.delivery_seconds - c.current_stage_elapsed)
      when 'delivered' then 0
      else null
    end::bigint as remaining_seconds
  from combined c
)
select
  r.order_id,
  r.stage,
  r.order_placed_at,
  r.merchant_accepted_at,
  r.preparation_started_at,
  r.ready_for_pickup_at,
  r.courier_assigned_at,
  r.picked_up_at,
  r.delivering_at,
  r.delivered_at,
  greatest(0, extract(epoch from coalesce(r.delivered_at, now()) - r.order_placed_at))::bigint,
  r.remaining_seconds,
  case when r.historical_eta then 'historical' else 'baseline' end,
  case
    when r.remaining_seconds is null then null
    else now() + r.remaining_seconds * interval '1 second'
  end
from remaining r;
$function$;

revoke all on function public.jib_order_timeline(uuid) from public, anon;
grant execute on function public.jib_order_timeline(uuid) to authenticated;

comment on function public.jib_order_timeline(uuid) is
  'Returns order lifecycle timestamps, elapsed time and a clearly labeled baseline or historical ETA for authorized participants.';
