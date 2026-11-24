create table if not exists public.merchant_prospects (
  id uuid primary key default gen_random_uuid(),
  business_name text not null,
  category text not null,
  address text not null,
  city text not null default 'Rabat',
  public_phone text,
  source_url text,
  source_name text not null default 'Public business listing',
  onboarding_status text not null default 'pending_owner_contact'
    check (onboarding_status in ('pending_owner_contact','contacted','owner_consent_received','declined')),
  owner_consent_received boolean not null default false,
  menu_verified boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.merchant_prospects enable row level security;
revoke all on public.merchant_prospects from anon, authenticated;
grant select, insert, update on public.merchant_prospects to authenticated;
drop policy if exists merchant_prospects_admin_only on public.merchant_prospects;
create policy merchant_prospects_admin_only on public.merchant_prospects
for all to authenticated
using (private.has_role(auth.uid(),'admin'))
with check (private.has_role(auth.uid(),'admin'));

-- Seed is inserted separately only after public business details are checked.
