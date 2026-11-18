-- Consolidate additive SELECT policies without changing their authorization semantics.
drop policy if exists order_events_admin_read on public.order_events;
drop policy if exists order_events_participant_read on public.order_events;
create policy order_events_admin_or_participant_read
  on public.order_events for select to authenticated
  using (
    (select public.is_jib_admin())
    or exists (
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
    )
  );

drop policy if exists order_items_admin_read on public.order_items;
drop policy if exists order_items_participant_read on public.order_items;
create policy order_items_admin_or_participant_read
  on public.order_items for select to authenticated
  using (
    (select public.is_jib_admin())
    or exists (
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
    )
  );

drop policy if exists orders_admin_read on public.orders;
drop policy if exists orders_assigned_courier_read on public.orders;
drop policy if exists orders_customer_read on public.orders;
drop policy if exists orders_store_owner_read on public.orders;
create policy orders_admin_or_participant_read
  on public.orders for select to authenticated
  using (
    (select public.is_jib_admin())
    or courier_id = (select auth.uid())
    or customer_id = (select auth.uid())
    or exists (
      select 1 from public.stores s
      where s.id = orders.store_id and s.owner_id = (select auth.uid())
    )
  );

drop policy if exists profiles_admin_read on public.profiles;
drop policy if exists profiles_read_own on public.profiles;
create policy profiles_admin_or_own_read
  on public.profiles for select to authenticated
  using ((select public.is_jib_admin()) or id = (select auth.uid()));

drop policy if exists products_admin_read on public.products;
drop policy if exists products_owner_manage on public.products;
drop policy if exists products_read_available on public.products;
create policy products_admin_available_or_owner_read
  on public.products for select to authenticated
  using (
    (select public.is_jib_admin())
    or (
      is_available = true
      and exists (
        select 1 from public.stores s
        where s.id = products.store_id and s.is_active = true
      )
    )
    or exists (
      select 1 from public.stores s
      where s.id = products.store_id and s.owner_id = (select auth.uid())
    )
  );
create policy products_owner_insert
  on public.products for insert to authenticated
  with check (exists (
    select 1 from public.stores s
    where s.id = products.store_id and s.owner_id = (select auth.uid())
  ));
create policy products_owner_update
  on public.products for update to authenticated
  using (exists (
    select 1 from public.stores s
    where s.id = products.store_id and s.owner_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.stores s
    where s.id = products.store_id and s.owner_id = (select auth.uid())
  ));
create policy products_owner_delete
  on public.products for delete to authenticated
  using (exists (
    select 1 from public.stores s
    where s.id = products.store_id and s.owner_id = (select auth.uid())
  ));

drop policy if exists stores_admin_read on public.stores;
drop policy if exists stores_owner_manage on public.stores;
drop policy if exists stores_read_active on public.stores;
create policy stores_admin_active_or_owner_read
  on public.stores for select to authenticated
  using (
    (select public.is_jib_admin())
    or is_active = true
    or owner_id = (select auth.uid())
  );
create policy stores_owner_insert
  on public.stores for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy stores_owner_update
  on public.stores for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
create policy stores_owner_delete
  on public.stores for delete to authenticated
  using (owner_id = (select auth.uid()));
