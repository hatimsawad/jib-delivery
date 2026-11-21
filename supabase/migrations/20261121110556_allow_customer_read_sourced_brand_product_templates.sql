-- Allow signed-in customers to browse sourced product templates for approved brands.
-- Templates remain non-orderable until a real store branch and live availability are verified.
grant select on table public.commercial_brand_product_templates to authenticated;

drop policy if exists "Customers read sourced templates for approved brands" on public.commercial_brand_product_templates;
create policy "Customers read sourced templates for approved brands"
  on public.commercial_brand_product_templates
  for select to authenticated
  using (
    official_source_url is not null
    and exists (
      select 1
      from public.commercial_brands b
      where b.id = brand_id
        and b.status = 'approved'
    )
  );
