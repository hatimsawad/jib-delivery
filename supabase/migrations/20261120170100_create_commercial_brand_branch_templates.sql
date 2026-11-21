create table if not exists public.commercial_brand_branch_templates (
 id uuid primary key default gen_random_uuid(), brand_id uuid not null references public.commercial_brands(id) on delete cascade,
 name text not null,address_text text not null,city text not null default 'Rabat',source_url text,
 status text not null default 'needs_branch_confirmation' check(status in ('draft','needs_branch_confirmation','ready_for_review','rejected')),
 is_active boolean not null default false,notes text,created_at timestamptz not null default now(),
 unique(brand_id,name,address_text)
);
alter table public.commercial_brand_branch_templates enable row level security;
revoke all on public.commercial_brand_branch_templates from anon,public;
grant select,insert,update on public.commercial_brand_branch_templates to authenticated;
drop policy if exists "JIB admins manage commercial branch templates" on public.commercial_brand_branch_templates;
create policy "JIB admins manage commercial branch templates" on public.commercial_brand_branch_templates for all to authenticated using(public.is_jib_admin()) with check(public.is_jib_admin());
create index if not exists commercial_brand_branch_templates_brand_city_idx on public.commercial_brand_branch_templates(brand_id,city,name);
