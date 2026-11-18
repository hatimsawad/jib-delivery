-- JIB AI Manager: private health history and incident tracking.
-- Scheduled invocation is configured separately because endpoint keys live in Supabase Vault.
create extension if not exists pg_cron;
create extension if not exists pg_net;

create table if not exists public.jib_ai_manager_health_checks (
  id uuid primary key default gen_random_uuid(),
  checked_at timestamptz not null default now(),
  status text not null check (status in ('healthy', 'degraded', 'down')),
  website_status integer,
  duration_ms integer not null default 0 check (duration_ms >= 0),
  metrics jsonb not null default '{}'::jsonb,
  issues jsonb not null default '[]'::jsonb
);
create index if not exists jib_ai_manager_health_checks_checked_at_idx
  on public.jib_ai_manager_health_checks (checked_at desc);

create table if not exists public.jib_ai_manager_events (
  id uuid primary key default gen_random_uuid(),
  fingerprint text not null unique,
  event_type text not null,
  severity text not null check (severity in ('info', 'warning', 'critical')),
  title text not null,
  message text not null,
  details jsonb not null default '{}'::jsonb,
  status text not null default 'open' check (status in ('open', 'acknowledged', 'resolved')),
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  resolved_at timestamptz,
  occurrence_count integer not null default 1 check (occurrence_count > 0)
);
create index if not exists jib_ai_manager_events_status_last_seen_idx
  on public.jib_ai_manager_events (status, last_seen_at desc);

alter table public.jib_ai_manager_health_checks enable row level security;
alter table public.jib_ai_manager_events enable row level security;
revoke all on public.jib_ai_manager_health_checks from public, anon, authenticated;
revoke all on public.jib_ai_manager_events from public, anon, authenticated;
grant select on public.jib_ai_manager_health_checks to authenticated;
grant select on public.jib_ai_manager_events to authenticated;
grant all on public.jib_ai_manager_health_checks to service_role;
grant all on public.jib_ai_manager_events to service_role;

drop policy if exists "JIB admins can read health checks" on public.jib_ai_manager_health_checks;
create policy "JIB admins can read health checks"
  on public.jib_ai_manager_health_checks for select to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  ));

drop policy if exists "JIB admins can read manager events" on public.jib_ai_manager_events;
create policy "JIB admins can read manager events"
  on public.jib_ai_manager_events for select to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  ));

create or replace function public.jib_ai_manager_monitor_secret()
returns text language sql stable security definer
set search_path = pg_catalog, vault
as $function$
  select v.decrypted_secret
  from vault.decrypted_secrets v
  where v.name = 'jib_ai_manager_monitor_secret'
  limit 1;
$function$;
revoke all on function public.jib_ai_manager_monitor_secret() from public, anon, authenticated;
grant execute on function public.jib_ai_manager_monitor_secret() to service_role;

comment on table public.jib_ai_manager_health_checks is 'Private history of scheduled JIB platform health checks.';
comment on table public.jib_ai_manager_events is 'Admin-only operational incident and activity log for JIB AI Manager.';
