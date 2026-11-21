-- Allow one batched, RLS-respecting timeline request for all visible recent orders.
create or replace function public.jib_order_timeline(p_order_id uuid default null)
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
  select o.id, o.status as order_status, o.created_at, o.updated_at
  from public.orders o
  where p_order_id is null or o.id = p_order_id
  order by o.created_at desc
  limit case when p_order_id is null then 100 else 1 end
),
timeline as (
  select
    e.order_id,
    min(e.created_at) filter (where e.status = 'pending') as order_placed_at,
    min(e.created_at) filter (where e.status = 'accepted') as merchant_accepted_at,
    min(e.created_at) filter (where e.status = 'preparing') as preparation_started_at,
    min(e.created_at) filter (where e.status = 'ready_for_pickup') as ready_for_pickup_at,
    min(e.created_at) filter (where e.status = 'courier_assigned') as courier_assigned_at,
    min(e.created_at) filter (where e.status = 'picked_up') as picked_up_at,
    min(e.created_at) filter (where e.status = 'delivering') as delivering_at,
    min(e.created_at) filter (where e.status = 'delivered') as delivered_at
  from public.order_events e
  join target t on t.id = e.order_id
  group by e.order_id
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
      when t.order_status in ('cancelled', 'rejected') then t.order_status
      when tl.delivered_at is not null or t.order_status = 'delivered' then 'delivered'
      when tl.delivering_at is not null or t.order_status = 'delivering' then 'delivering'
      when tl.picked_up_at is not null or t.order_status = 'picked_up' then 'picked_up'
      when tl.courier_assigned_at is not null then 'courier_assigned'
      when tl.ready_for_pickup_at is not null or t.order_status = 'ready_for_pickup' then 'ready_for_pickup'
      when tl.preparation_started_at is not null or t.order_status = 'preparing' then 'preparing'
      when tl.merchant_accepted_at is not null or t.order_status = 'accepted' then 'accepted'
      else t.order_status
    end as stage,
    coalesce(tl.order_placed_at, t.created_at) as order_placed_at,
    tl.merchant_accepted_at,
    tl.preparation_started_at,
    tl.ready_for_pickup_at,
    tl.courier_assigned_at,
    tl.picked_up_at,
    tl.delivering_at,
    coalesce(tl.delivered_at, case when t.order_status = 'delivered' then t.updated_at end) as delivered_at,
    d.*,
    greatest(0, extract(epoch from now() - case
      when t.order_status in ('cancelled', 'rejected') then coalesce(tl.order_placed_at, t.created_at)
      when tl.delivered_at is not null or t.order_status = 'delivered' then coalesce(tl.delivered_at, t.updated_at)
      when tl.delivering_at is not null or tl.picked_up_at is not null or t.order_status in ('picked_up', 'delivering')
        then coalesce(tl.picked_up_at, tl.delivering_at, t.updated_at)
      when tl.courier_assigned_at is not null then coalesce(tl.courier_assigned_at, t.updated_at)
      when tl.ready_for_pickup_at is not null or t.order_status = 'ready_for_pickup' then coalesce(tl.ready_for_pickup_at, t.updated_at)
      when tl.preparation_started_at is not null or t.order_status = 'preparing' then coalesce(tl.preparation_started_at, t.updated_at)
      when tl.merchant_accepted_at is not null or t.order_status = 'accepted' then coalesce(tl.merchant_accepted_at, t.updated_at)
      else coalesce(tl.order_placed_at, t.created_at)
    end))::bigint as current_stage_elapsed
  from target t
  left join timeline tl on tl.order_id = t.id
  cross join durations d
),
remaining as (
  select
    c.*,
    case c.stage
      when 'pending' then greatest(0, c.acceptance_seconds - c.current_stage_elapsed)
        + c.preparation_seconds + c.matching_seconds + c.pickup_seconds + c.delivery_seconds
      when 'accepted' then greatest(0, c.preparation_seconds - c.current_stage_elapsed)
        + c.matching_seconds + c.pickup_seconds + c.delivery_seconds
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
    when r.stage in ('cancelled', 'rejected') then null
    when r.stage = 'delivered' then r.delivered_at
    when r.remaining_seconds is null then null
    else now() + r.remaining_seconds * interval '1 second'
  end
from remaining r;
$function$;
