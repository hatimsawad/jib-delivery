create table if not exists public.jib_ai_manager_settings (
  id smallint primary key default 1 check (id = 1),
  notification_email text not null default '',
  notification_phone text not null default '',
  notification_phone_e164 text not null default '',
  notification_channels text[] not null default array['email', 'sms']::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint jib_ai_manager_channels_check
    check (
      notification_channels @> array['email', 'sms']::text[]
      and cardinality(notification_channels) = 2
    )
);

alter table public.jib_ai_manager_settings enable row level security;
revoke all on public.jib_ai_manager_settings from public, anon, authenticated;
grant select on public.jib_ai_manager_settings to authenticated;

drop policy if exists "Admins can read JIB AI manager settings" on public.jib_ai_manager_settings;
create policy "Admins can read JIB AI manager settings"
  on public.jib_ai_manager_settings for select to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  ));

drop policy if exists "Admins can update JIB AI manager settings" on public.jib_ai_manager_settings;
create policy "Admins can update JIB AI manager settings"
  on public.jib_ai_manager_settings for update to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  ))
  with check (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  ));

insert into public.jib_ai_manager_settings (
  id, notification_email, notification_phone, notification_phone_e164, notification_channels
)
values (1, '', '', '', array['email', 'sms']::text[])
on conflict (id) do nothing;
