-- Optimize read policies without widening catalog or integration access.
-- Anonymous users can only read approved public brand records. Signed-in admins
-- can also read pending records and manage the catalog. Store integration metadata
-- is private to branch owners and JIB admins; writes remain admin-only.

create index if not exists store_branch_policies_updated_by_idx
  on public.store_branch_policies(updated_by);

create index if not exists commercial_brand_aliases_brand_id_idx
  on public.commercial_brand_aliases(brand_id);

drop policy if exists "commercial_brands_admin_all" on public.commercial_brands;
drop policy if exists "commercial_brands_public_approved_read" on public.commercial_brands;

create policy "commercial_brands_anon_approved_read"
  on public.commercial_brands
  for select to anon
  using (status = 'approved');

create policy "commercial_brands_authenticated_read"
  on public.commercial_brands
  for select to authenticated
  using (status = 'approved' or (select public.is_jib_admin()));

create policy "commercial_brands_admin_insert"
  on public.commercial_brands
  for insert to authenticated
  with check ((select public.is_jib_admin()));

create policy "commercial_brands_admin_update"
  on public.commercial_brands
  for update to authenticated
  using ((select public.is_jib_admin()))
  with check ((select public.is_jib_admin()));

create policy "commercial_brands_admin_delete"
  on public.commercial_brands
  for delete to authenticated
  using ((select public.is_jib_admin()));

drop policy if exists "commercial_brand_aliases_admin_all" on public.commercial_brand_aliases;
drop policy if exists "commercial_brand_aliases_public_approved_read" on public.commercial_brand_aliases;

create policy "commercial_brand_aliases_anon_approved_read"
  on public.commercial_brand_aliases
  for select to anon
  using (exists (
    select 1 from public.commercial_brands b
    where b.id = brand_id and b.status = 'approved'
  ));

create policy "commercial_brand_aliases_authenticated_read"
  on public.commercial_brand_aliases
  for select to authenticated
  using (
    (select public.is_jib_admin())
    or exists (
      select 1 from public.commercial_brands b
      where b.id = brand_id and b.status = 'approved'
    )
  );

create policy "commercial_brand_aliases_admin_insert"
  on public.commercial_brand_aliases
  for insert to authenticated
  with check ((select public.is_jib_admin()));

create policy "commercial_brand_aliases_admin_update"
  on public.commercial_brand_aliases
  for update to authenticated
  using ((select public.is_jib_admin()))
  with check ((select public.is_jib_admin()));

create policy "commercial_brand_aliases_admin_delete"
  on public.commercial_brand_aliases
  for delete to authenticated
  using ((select public.is_jib_admin()));

drop policy if exists "store_integrations_admin_all" on public.store_integrations;
drop policy if exists "store_integrations_owner_read" on public.store_integrations;

create policy "store_integrations_owner_or_admin_read"
  on public.store_integrations
  for select to authenticated
  using (
    (select public.is_jib_admin())
    or exists (
      select 1 from public.stores s
      where s.id = store_id and s.owner_id = (select auth.uid())
    )
  );

create policy "store_integrations_admin_insert"
  on public.store_integrations
  for insert to authenticated
  with check ((select public.is_jib_admin()));

create policy "store_integrations_admin_update"
  on public.store_integrations
  for update to authenticated
  using ((select public.is_jib_admin()))
  with check ((select public.is_jib_admin()));

create policy "store_integrations_admin_delete"
  on public.store_integrations
  for delete to authenticated
  using ((select public.is_jib_admin()));

revoke all privileges on table public.store_integrations from anon, public;
grant select, insert, update, delete on table public.store_integrations to authenticated;
