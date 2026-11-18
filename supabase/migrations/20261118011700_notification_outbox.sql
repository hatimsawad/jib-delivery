-- Queue every manager event for the configured owner channels, without sending until providers are approved.
create table if not exists public.jib_ai_manager_notification_outbox (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.jib_ai_manager_events(id) on delete cascade,
  channel text not null check (channel in ('email','sms','whatsapp','voice')),
  recipient text,
  status text not null default 'awaiting_provider'
    check (status in ('awaiting_provider','pending','processing','sent','failed','skipped')),
  payload jsonb not null default '{}'::jsonb,
  blocked_reason text,
  attempts integer not null default 0 check (attempts >= 0),
  provider_message_id text,
  created_at timestamptz not null default now(),
  next_attempt_at timestamptz,
  sent_at timestamptz,
  unique (event_id, channel)
);

create index if not exists jib_ai_manager_notification_outbox_status_idx
  on public.jib_ai_manager_notification_outbox (status, next_attempt_at, created_at);

alter table public.jib_ai_manager_notification_outbox enable row level security;
revoke all on public.jib_ai_manager_notification_outbox from public, anon, authenticated;
grant select on public.jib_ai_manager_notification_outbox to authenticated;
grant all on public.jib_ai_manager_notification_outbox to service_role;

drop policy if exists "JIB admins can read notification outbox" on public.jib_ai_manager_notification_outbox;
create policy "JIB admins can read notification outbox"
  on public.jib_ai_manager_notification_outbox for select to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  ));

create or replace function public.jib_ai_manager_enqueue_notification_jobs()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $function$
declare
  v_settings record;
  v_channel text;
  v_recipient text;
  v_status text;
  v_blocked_reason text;
begin
  select notification_email, notification_phone_e164, notification_channels,
         notification_call_mode, notification_voice_languages
  into v_settings
  from public.jib_ai_manager_settings
  where id = 1;

  if not found then
    return new;
  end if;

  foreach v_channel in array v_settings.notification_channels loop
    v_recipient := case
      when v_channel = 'email' then nullif(trim(v_settings.notification_email), '')
      else nullif(trim(v_settings.notification_phone_e164), '')
    end;

    v_status := 'awaiting_provider';
    v_blocked_reason := 'provider_not_configured';

    if v_recipient is null then
      v_status := 'skipped';
      v_blocked_reason := 'recipient_not_configured';
    elsif v_channel = 'voice'
      and v_settings.notification_call_mode = 'critical_only'
      and new.severity <> 'critical' then
      v_status := 'skipped';
      v_blocked_reason := 'voice_policy_critical_only';
    end if;

    insert into public.jib_ai_manager_notification_outbox (
      event_id, channel, recipient, status, payload, blocked_reason
    ) values (
      new.id,
      v_channel,
      v_recipient,
      v_status,
      jsonb_build_object(
        'event_type', new.event_type,
        'severity', new.severity,
        'title', new.title,
        'message', new.message,
        'details', new.details,
        'voice_languages', v_settings.notification_voice_languages
      ),
      v_blocked_reason
    )
    on conflict (event_id, channel) do nothing;
  end loop;

  return new;
end;
$function$;

revoke all on function public.jib_ai_manager_enqueue_notification_jobs() from public, anon, authenticated;

drop trigger if exists jib_ai_manager_enqueue_notifications on public.jib_ai_manager_events;
create trigger jib_ai_manager_enqueue_notifications
  after insert on public.jib_ai_manager_events
  for each row execute function public.jib_ai_manager_enqueue_notification_jobs();

comment on table public.jib_ai_manager_notification_outbox is
  'Private idempotent delivery queue. Jobs stay awaiting_provider until verified delivery providers are configured and owner approves activation.';
