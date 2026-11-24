create index if not exists order_items_product_id_idx
  on public.order_items(product_id) where product_id is not null;

drop policy if exists merchant_prospects_admin_only on public.merchant_prospects;
create policy merchant_prospects_admin_only on public.merchant_prospects
for all to authenticated
using ((select private.has_role((select auth.uid()), 'admin')))
with check ((select private.has_role((select auth.uid()), 'admin')));
