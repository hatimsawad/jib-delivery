-- Admin read access for the operations dashboard.
-- public.is_jib_admin() is SECURITY DEFINER to avoid recursive RLS on profiles.
create or replace function public.is_jib_admin()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  );
$$;

revoke all on function public.is_jib_admin() from public, anon;
grant execute on function public.is_jib_admin() to authenticated;

create policy "profiles_admin_read"
  on public.profiles for select to authenticated
  using (public.is_jib_admin());

create policy "stores_admin_read"
  on public.stores for select to authenticated
  using (public.is_jib_admin());

create policy "products_admin_read"
  on public.products for select to authenticated
  using (public.is_jib_admin());

create policy "orders_admin_read"
  on public.orders for select to authenticated
  using (public.is_jib_admin());

create policy "order_items_admin_read"
  on public.order_items for select to authenticated
  using (public.is_jib_admin());

create policy "order_events_admin_read"
  on public.order_events for select to authenticated
  using (public.is_jib_admin());
