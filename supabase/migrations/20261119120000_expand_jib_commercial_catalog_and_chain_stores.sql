-- Expand JIB from a food-first catalog to a multi-vertical commercial marketplace.
-- Additive only: existing store/product/order data and workflows remain compatible.

alter table public.stores
  add column if not exists brand_name text,
  add column if not exists brand_logo_url text,
  add column if not exists is_chain boolean not null default false,
  add column if not exists integration_mode text not null default 'manual'
    check (integration_mode in ('manual', 'partner_api', 'pos')),
  add column if not exists external_store_id text,
  add column if not exists onboarding_status text not null default 'pending'
    check (onboarding_status in ('pending', 'review', 'approved', 'rejected', 'suspended'));

alter table public.products
  add column if not exists category text not null default 'general-merchandise',
  add column if not exists brand_name text,
  add column if not exists sku text,
  add column if not exists barcode text,
  add column if not exists attributes jsonb not null default '{}'::jsonb,
  add column if not exists external_product_id text;

create index if not exists products_store_category_available_idx
  on public.products(store_id, category, is_available);
create index if not exists stores_chain_brand_idx
  on public.stores(is_chain, brand_name)
  where is_chain = true;

-- Connection metadata only. Provider credentials/tokens must never be stored in this table.
create table if not exists public.store_integrations (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  provider text not null,
  integration_type text not null default 'manual'
    check (integration_type in ('manual', 'partner_api', 'pos', 'catalog_import')),
  status text not null default 'not_connected'
    check (status in ('not_connected', 'pending_partner', 'connected', 'paused', 'error')),
  external_account_id text,
  settings jsonb not null default '{}'::jsonb,
  last_synced_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (store_id, provider)
);

create index if not exists store_integrations_store_status_idx
  on public.store_integrations(store_id, status);

alter table public.store_integrations enable row level security;

create policy "store_integrations_owner_read"
  on public.store_integrations for select to authenticated
  using (exists (
    select 1 from public.stores s
    where s.id = store_id and s.owner_id = (select auth.uid())
  ));

create policy "store_integrations_owner_insert"
  on public.store_integrations for insert to authenticated
  with check (exists (
    select 1 from public.stores s
    where s.id = store_id and s.owner_id = (select auth.uid())
  ));

create policy "store_integrations_owner_update"
  on public.store_integrations for update to authenticated
  using (exists (
    select 1 from public.stores s
    where s.id = store_id and s.owner_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.stores s
    where s.id = store_id and s.owner_id = (select auth.uid())
  ));

create policy "store_integrations_admin_all"
  on public.store_integrations for all to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  ))
  with check (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  ));
