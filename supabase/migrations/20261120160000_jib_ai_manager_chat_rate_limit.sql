-- Persistent per-admin rate limiting for the advisory JIB AI Manager chat.
-- No direct table access is granted; the authenticated RPC performs the atomic update.
create table if not exists public.jib_ai_manager_chat_rate_limits (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_started_at timestamptz not null,
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default now()
);

alter table public.jib_ai_manager_chat_rate_limits enable row level security;
revoke all on table public.jib_ai_manager_chat_rate_limits from public, anon, authenticated;

create or replace function public.jib_ai_manager_consume_chat_rate_limit()
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $$
declare
  v_uid uuid := (select auth.uid());
  v_now timestamptz := clock_timestamp();
  v_count integer;
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;
  if not public.is_jib_admin() then
    raise exception 'JIB administrator access required';
  end if;

  insert into public.jib_ai_manager_chat_rate_limits (
    user_id, window_started_at, request_count, updated_at
  ) values (v_uid, v_now, 1, v_now)
  on conflict (user_id) do update
    set window_started_at = case
          when public.jib_ai_manager_chat_rate_limits.window_started_at <= v_now - interval '1 hour'
            then v_now
          else public.jib_ai_manager_chat_rate_limits.window_started_at
        end,
        request_count = case
          when public.jib_ai_manager_chat_rate_limits.window_started_at <= v_now - interval '1 hour'
            then 1
          else public.jib_ai_manager_chat_rate_limits.request_count + 1
        end,
        updated_at = v_now
  returning request_count into v_count;

  return v_count <= 20;
end;
$$;

revoke all on function public.jib_ai_manager_consume_chat_rate_limit() from public, anon;
grant execute on function public.jib_ai_manager_consume_chat_rate_limit() to authenticated;

comment on table public.jib_ai_manager_chat_rate_limits is
  'Private per-admin fixed-window rate limit for advisory AI Manager chat; direct table access is revoked.';
