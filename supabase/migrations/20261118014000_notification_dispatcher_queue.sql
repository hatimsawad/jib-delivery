-- Durable dispatcher queue support; no provider is enabled by this migration.
alter table public.jib_ai_manager_notification_outbox
  add column if not exists locked_at timestamptz,
  add column if not exists estimated_cost_usd numeric(10,4);

create index if not exists jib_ai_manager_notification_outbox_claim_idx
  on public.jib_ai_manager_notification_outbox (channel, status, next_attempt_at, created_at);

create or replace function public.jib_ai_manager_claim_notifications(
  p_channels text[],
  p_limit integer default 20
)
returns setof public.jib_ai_manager_notification_outbox
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $function$
declare
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
begin
  update public.jib_ai_manager_notification_outbox
  set status = 'pending',
      locked_at = null,
      next_attempt_at = now(),
      blocked_reason = 'stale_processing_recovered'
  where status = 'processing'
    and locked_at is not null
    and locked_at < now() - interval '10 minutes';

  return query
  with claimable as (
    select o.id
    from public.jib_ai_manager_notification_outbox o
    where o.channel = any(coalesce(p_channels, array[]::text[]))
      and o.status in ('awaiting_provider','pending')
      and (o.next_attempt_at is null or o.next_attempt_at <= now())
    order by o.created_at asc
    for update skip locked
    limit v_limit
  )
  update public.jib_ai_manager_notification_outbox o
  set status = 'processing',
      attempts = o.attempts + 1,
      locked_at = now(),
      blocked_reason = null
  from claimable c
  where o.id = c.id
  returning o.*;
end;
$function$;

revoke all on function public.jib_ai_manager_claim_notifications(text[],integer) from public, anon, authenticated;
grant execute on function public.jib_ai_manager_claim_notifications(text[],integer) to service_role;

do $$
begin
  if not exists (
    select 1 from vault.decrypted_secrets where name = 'jib_ai_manager_dispatch_secret'
  ) then
    perform vault.create_secret(
      encode(gen_random_bytes(32), 'hex'),
      'jib_ai_manager_dispatch_secret',
      'Private webhook secret for the JIB AI Manager notification dispatcher'
    );
  end if;
end
$$;

create or replace function public.jib_ai_manager_dispatch_secret()
returns text
language sql
stable
security definer
set search_path = pg_catalog, vault
as $function$
  select v.decrypted_secret
  from vault.decrypted_secrets v
  where v.name = 'jib_ai_manager_dispatch_secret'
  limit 1;
$function$;

revoke all on function public.jib_ai_manager_dispatch_secret() from public, anon, authenticated;
grant execute on function public.jib_ai_manager_dispatch_secret() to service_role;
