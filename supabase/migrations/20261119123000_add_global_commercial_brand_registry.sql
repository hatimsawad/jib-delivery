-- Global brand registry for worldwide chains and independent labels.
-- Stores remain the branch/merchant records; each branch may reference one canonical brand.
-- This migration is additive and does not create partnerships or import protected brand assets.

create table if not exists public.commercial_brands (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  normalized_name text not null,
  slug text not null unique,
  category text not null default 'general-merchandise',
  website_url text,
  country_code text,
  logo_url text,
  status text not null default 'pending_verification'
    check (status in ('draft', 'pending_verification', 'approved', 'rejected', 'suspended')),
  source_name text,
  source_url text,
  source_license text,
  verified_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (country_code is null or country_code ~ '^[A-Z]{2}$'),
  check (website_url is null or website_url ~ '^https?://'),
  check (source_url is null or source_url ~ '^https?://')
);

create index if not exists commercial_brands_status_category_idx
  on public.commercial_brands(status, category);
create index if not exists commercial_brands_normalized_name_idx
  on public.commercial_brands(normalized_name);

create table if not exists public.commercial_brand_aliases (
  id uuid primary key default gen_random_uuid(),
  brand_id uuid not null references public.commercial_brands(id) on delete cascade,
  locale text not null default 'und',
  alias text not null,
  normalized_alias text not null,
  created_at timestamptz not null default now(),
  unique (brand_id, locale, normalized_alias)
);

create index if not exists commercial_brand_aliases_lookup_idx
  on public.commercial_brand_aliases(normalized_alias);

alter table public.stores
  add column if not exists brand_id uuid references public.commercial_brands(id) on delete set null;

alter table public.products
  add column if not exists brand_id uuid references public.commercial_brands(id) on delete set null;

create index if not exists stores_brand_id_idx on public.stores(brand_id);
create index if not exists products_brand_id_idx on public.products(brand_id);

-- Explicit Data API grants; RLS below remains the row-level security boundary.
grant select on public.commercial_brands to anon, authenticated;
grant insert, update, delete on public.commercial_brands to authenticated;
grant select on public.commercial_brand_aliases to anon, authenticated;
grant insert, update, delete on public.commercial_brand_aliases to authenticated;

alter table public.commercial_brands enable row level security;
alter table public.commercial_brand_aliases enable row level security;

drop policy if exists "commercial_brands_public_approved_read" on public.commercial_brands;
create policy "commercial_brands_public_approved_read"
  on public.commercial_brands for select
  using (status = 'approved');

drop policy if exists "commercial_brands_admin_all" on public.commercial_brands;
create policy "commercial_brands_admin_all"
  on public.commercial_brands for all to authenticated
  using ((select public.is_jib_admin()))
  with check ((select public.is_jib_admin()));

drop policy if exists "commercial_brand_aliases_public_approved_read" on public.commercial_brand_aliases;
create policy "commercial_brand_aliases_public_approved_read"
  on public.commercial_brand_aliases for select
  using (exists (
    select 1 from public.commercial_brands b
    where b.id = brand_id and b.status = 'approved'
  ));

drop policy if exists "commercial_brand_aliases_admin_all" on public.commercial_brand_aliases;
create policy "commercial_brand_aliases_admin_all"
  on public.commercial_brand_aliases for all to authenticated
  using ((select public.is_jib_admin()))
  with check ((select public.is_jib_admin()));

comment on table public.commercial_brands is
  'Canonical global brand directory. Approval and partner authorization are separate concepts.';
comment on table public.commercial_brand_aliases is
  'Localized brand names and search aliases; only admin-managed records are writable.';
