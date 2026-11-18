-- Optimize per-row RLS predicates by evaluating stable auth context once per statement.
alter policy addresses_owner_manage on public.addresses
  using (customer_id = (select auth.uid()))
  with check (customer_id = (select auth.uid()));

alter policy courier_profiles_read_own_or_admin on public.courier_profiles
  using (user_id = (select auth.uid()) or (select public.is_jib_admin()));

alter policy order_events_admin_read on public.order_events
  using ((select public.is_jib_admin()));
alter policy order_events_participant_read on public.order_events
  using (exists (
    select 1 from public.orders o
    where o.id = order_events.order_id
      and (
        o.customer_id = (select auth.uid())
        or o.courier_id = (select auth.uid())
        or exists (
          select 1 from public.stores s
          where s.id = o.store_id and s.owner_id = (select auth.uid())
        )
      )
  ));

alter policy order_items_admin_read on public.order_items
  using ((select public.is_jib_admin()));
alter policy order_items_participant_read on public.order_items
  using (exists (
    select 1 from public.orders o
    where o.id = order_items.order_id
      and (
        o.customer_id = (select auth.uid())
        or o.courier_id = (select auth.uid())
        or exists (
          select 1 from public.stores s
          where s.id = o.store_id and s.owner_id = (select auth.uid())
        )
      )
  ));

alter policy orders_admin_read on public.orders
  using ((select public.is_jib_admin()));
alter policy orders_assigned_courier_read on public.orders
  using (courier_id = (select auth.uid()));
alter policy orders_customer_read on public.orders
  using (customer_id = (select auth.uid()));
alter policy orders_store_owner_read on public.orders
  using (exists (
    select 1 from public.stores s
    where s.id = orders.store_id and s.owner_id = (select auth.uid())
  ));

alter policy products_admin_read on public.products
  using ((select public.is_jib_admin()));
alter policy products_owner_manage on public.products
  using (exists (
    select 1 from public.stores s
    where s.id = products.store_id and s.owner_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.stores s
    where s.id = products.store_id and s.owner_id = (select auth.uid())
  ));
alter policy products_read_available on public.products
  using (
    (
      is_available = true
      and exists (select 1 from public.stores s where s.id = products.store_id and s.is_active = true)
    )
    or exists (select 1 from public.stores s where s.id = products.store_id and s.owner_id = (select auth.uid()))
  );

alter policy profiles_admin_read on public.profiles
  using ((select public.is_jib_admin()));
alter policy profiles_read_own on public.profiles
  using (id = (select auth.uid()));
alter policy profiles_update_own on public.profiles
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

alter policy stores_admin_read on public.stores
  using ((select public.is_jib_admin()));
alter policy stores_owner_manage on public.stores
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
alter policy stores_read_active on public.stores
  using (is_active = true or owner_id = (select auth.uid()));
