-- Extend JIB AI Manager preferences to all requested notification channels.
alter table public.jib_ai_manager_settings
  add column if not exists notification_call_mode text not null default 'critical_only'
    check (notification_call_mode in ('critical_only','all_events')),
  add column if not exists notification_voice_languages text[] not null default array['ar']::text[]
    check (
      notification_voice_languages <@ array['ar','fr']::text[]
      and cardinality(notification_voice_languages) between 1 and 2
    );

alter table public.jib_ai_manager_settings
  drop constraint if exists jib_ai_manager_channels_check;

update public.jib_ai_manager_settings
set notification_channels = array['email','sms','whatsapp','voice']::text[],
    notification_call_mode = 'all_events',
    notification_voice_languages = array['ar','fr']::text[],
    updated_at = now()
where id = 1;

alter table public.jib_ai_manager_settings
  add constraint jib_ai_manager_channels_check
  check (
    notification_channels @> array['email','sms','whatsapp','voice']::text[]
    and cardinality(notification_channels) = 4
  );
