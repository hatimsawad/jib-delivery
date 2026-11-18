-- Complete notification preference schema for the standalone JIB Manager.
-- Provider delivery remains disabled until credentials and end-to-end tests are configured.
create table if not exists public.jib_ai_manager_settings (
  id smallint primary key default 1 check (id = 1),
  notification_email text not null default '',
  notification_phone text not null default '',
  notification_phone_e164 text not null default '',
  notification_channels text[] not null default array['email','sms','whatsapp','voice']::text[],
  notification_call_mode text not null default 'all_events',
  notification_voice_languages text[] not null default array['ar','fr']::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.jib_ai_manager_settings
  add column if not exists notification_call_mode text not null default 'all_events',
  add column if not exists notification_voice_languages text[] not null default array['ar','fr']::text[];

alter table public.jib_ai_manager_settings
  drop constraint if exists jib_ai_manager_channels_check,
  drop constraint if exists jib_ai_manager_settings_notification_call_mode_check,
  drop constraint if exists jib_ai_manager_settings_notification_voice_languages_check;

alter table public.jib_ai_manager_settings
  add constraint jib_ai_manager_channels_check
    check (
      notification_channels @> array['email','sms','whatsapp','voice']::text[]
      and cardinality(notification_channels) = 4
    ),
  add constraint jib_ai_manager_settings_notification_call_mode_check
    check (notification_call_mode in ('critical_only','all_events')),
  add constraint jib_ai_manager_settings_notification_voice_languages_check
    check (
      notification_voice_languages <@ array['ar','fr']::text[]
      and cardinality(notification_voice_languages) between 1 and 2
    );

alter table public.jib_ai_manager_settings enable row level security;
revoke all on table public.jib_ai_manager_settings from public, anon, authenticated;
grant select on table public.jib_ai_manager_settings to authenticated;

drop policy if exists "Admins can read JIB AI manager settings" on public.jib_ai_manager_settings;
create policy "Admins can read JIB AI manager settings"
  on public.jib_ai_manager_settings for select to authenticated
  using (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin'));

drop policy if exists "Admins can update JIB AI manager settings" on public.jib_ai_manager_settings;
create policy "Admins can update JIB AI manager settings"
  on public.jib_ai_manager_settings for update to authenticated
  using (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin'))
  with check (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin'));

-- Do not seed private email addresses or phone numbers into a public migration.
insert into public.jib_ai_manager_settings (id, notification_email, notification_phone, notification_phone_e164)
values (1, '', '', '')
on conflict (id) do nothing;

comment on table public.jib_ai_manager_settings is
  'Private JIB Manager notification preferences. Delivery providers and credentials are configured separately.';
