-- Safe pre-launch catalogue templates. No real store/product visibility is enabled.
create table if not exists public.commercial_brand_product_templates (
 id uuid primary key default gen_random_uuid(),
 brand_id uuid not null references public.commercial_brands(id) on delete cascade,
 name text not null check(length(trim(name)) between 1 and 180),
 normalized_name text not null, category text not null, official_source_url text,
 status text not null default 'draft' check(status in ('draft','needs_branch_confirmation','ready_for_review','rejected')),
 price_mad numeric(10,2), is_active boolean not null default false, notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(brand_id,normalized_name)
);
alter table public.commercial_brand_product_templates enable row level security;
revoke all on public.commercial_brand_product_templates from anon, public;
grant select,insert,update on public.commercial_brand_product_templates to authenticated;
drop policy if exists "JIB admins manage commercial product templates" on public.commercial_brand_product_templates;
create policy "JIB admins manage commercial product templates" on public.commercial_brand_product_templates for all to authenticated using(public.is_jib_admin()) with check(public.is_jib_admin());
create index if not exists commercial_brand_product_templates_brand_category_idx on public.commercial_brand_product_templates(brand_id,category,name);
comment on table public.commercial_brand_product_templates is 'Draft pre-launch templates; not customer-orderable and no branch, price or availability is implied.';
