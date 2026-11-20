-- Consent-based courier location tracking with a strict 90-day retention window.
create table if not exists public.courier_location_tracking (
  courier_id uuid primary key references auth.users(id) on delete cascade,
  consented_at timestamptz not null,
  tracking_enabled boolean not null default true,
  last_location_at timestamptz,
  stopped_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.courier_location_events (
  id uuid primary key default gen_random_uuid(),
  courier_id uuid not null references auth.users(id) on delete cascade,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  accuracy_m double precision not null check (accuracy_m >= 0 and accuracy_m <= 10000),
  recorded_at timestamptz not null default now()
);

create index if not exists courier_location_events_courier_recorded_idx
  on public.courier_location_events(courier_id, recorded_at desc);
create index if not exists courier_location_tracking_enabled_last_location_idx
  on public.courier_location_tracking(last_location_at)
  where tracking_enabled = true;

alter table public.courier_location_tracking enable row level security;
alter table public.courier_location_events enable row level security;
revoke all on public.courier_location_tracking from public, anon, authenticated;
revoke all on public.courier_location_events from public, anon, authenticated;
grant select on public.courier_location_tracking to authenticated;
grant select on public.courier_location_events to authenticated;

drop policy if exists courier_location_tracking_admin_read on public.courier_location_tracking;
create policy courier_location_tracking_admin_read
  on public.courier_location_tracking for select to authenticated
  using ((select public.is_jib_admin()));

drop policy if exists courier_location_events_admin_read on public.courier_location_events;
create policy courier_location_events_admin_read
  on public.courier_location_events for select to authenticated
  using ((select public.is_jib_admin()));

create or replace function public.set_courier_location_consent(p_enabled boolean)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  if p_enabled then
    if not exists (
      select 1 from public.courier_profiles cp
      where cp.user_id = v_uid and cp.is_active = true
    ) then
      raise exception 'Only approved active couriers can enable location sharing';
    end if;
    insert into public.courier_location_tracking (
      courier_id, consented_at, tracking_enabled, stopped_at, updated_at
    ) values (v_uid, now(), true, null, now())
    on conflict (courier_id) do update
      set consented_at = now(), tracking_enabled = true, stopped_at = null, updated_at = now();
  else
    update public.courier_location_tracking
    set tracking_enabled = false, stopped_at = now(), updated_at = now()
    where courier_id = v_uid;
  end if;
end;
$$;

create or replace function public.record_courier_location(
  p_latitude double precision,
  p_longitude double precision,
  p_accuracy_m double precision
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  if p_latitude is null or p_latitude not between -90 and 90
     or p_longitude is null or p_longitude not between -180 and 180
     or p_accuracy_m is null or p_accuracy_m < 0 or p_accuracy_m > 10000 then
    raise exception 'Invalid location coordinates or accuracy';
  end if;
  if not exists (
    select 1 from public.courier_profiles cp
    where cp.user_id = v_uid and cp.is_active = true
  ) then
    raise exception 'Only approved active couriers can submit location';
  end if;
  if not exists (
    select 1 from public.courier_location_tracking t
    where t.courier_id = v_uid and t.tracking_enabled = true
  ) then
    raise exception 'Location sharing consent is not active';
  end if;

  insert into public.courier_location_events(courier_id, latitude, longitude, accuracy_m)
  values (v_uid, p_latitude, p_longitude, p_accuracy_m);

  update public.courier_location_tracking
  set last_location_at = now(), updated_at = now()
  where courier_id = v_uid;

  update public.jib_ai_manager_events
  set status = 'resolved', resolved_at = now(), last_seen_at = now()
  where fingerprint = 'courier-location-stale:' || v_uid::text
    and status <> 'resolved';
end;
$$;

create or replace function public.jib_check_courier_location_staleness()
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $$
declare
  v_count integer := 0;
  v_tracking record;
begin
  for v_tracking in
    select t.courier_id, t.last_location_at
    from public.courier_location_tracking t
    join public.courier_profiles cp on cp.user_id = t.courier_id and cp.is_active = true
    where t.tracking_enabled = true
      and (t.last_location_at is null or t.last_location_at < now() - interval '60 seconds')
  loop
    insert into public.jib_ai_manager_events (
      fingerprint, event_type, severity, title, message, details, status,
      first_seen_at, last_seen_at, occurrence_count
    ) values (
      'courier-location-stale:' || v_tracking.courier_id::text,
      'courier_location_disconnected',
      'warning',
      'انقطاع تحديث موقع مندوب',
      'لم يصل تحديث موقع المندوب خلال 60 ثانية أثناء تفعيل مشاركة الموقع.',
      jsonb_build_object('courier_id', v_tracking.courier_id, 'last_location_at', v_tracking.last_location_at),
      'open', now(), now(), 1
    )
    on conflict (fingerprint) do update
      set last_seen_at = now(),
          occurrence_count = public.jib_ai_manager_events.occurrence_count + 1,
          status = 'open',
          resolved_at = null;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

create or replace function public.jib_prune_courier_location_history()
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $$
declare v_deleted integer;
begin
  delete from public.courier_location_events
  where recorded_at < now() - interval '90 days';
  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;

revoke all on function public.set_courier_location_consent(boolean) from public, anon;
grant execute on function public.set_courier_location_consent(boolean) to authenticated;
revoke all on function public.record_courier_location(double precision, double precision, double precision) from public, anon;
grant execute on function public.record_courier_location(double precision, double precision, double precision) to authenticated;
revoke all on function public.jib_check_courier_location_staleness() from public, anon, authenticated;
revoke all on function public.jib_prune_courier_location_history() from public, anon, authenticated;

do $$
declare v_job_id bigint;
begin
  select jobid into v_job_id from cron.job where jobname = 'jib-courier-location-stale-check';
  if v_job_id is not null then perform cron.unschedule(v_job_id); end if;
  perform cron.schedule('jib-courier-location-stale-check', '* * * * *',
    'select public.jib_check_courier_location_staleness()');

  select jobid into v_job_id from cron.job where jobname = 'jib-courier-location-prune';
  if v_job_id is not null then perform cron.unschedule(v_job_id); end if;
  perform cron.schedule('jib-courier-location-prune', '17 3 * * *',
    'select public.jib_prune_courier_location_history()');
end;
$$;
