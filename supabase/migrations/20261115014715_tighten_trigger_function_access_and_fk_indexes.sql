-- Restrict trigger-only SECURITY DEFINER functions from direct API/RPC execution.
revoke all on function public.guard_profile_role() from public, anon, authenticated;
revoke all on function public.handle_new_auth_user() from public, anon, authenticated;

-- Add indexes for frequently joined foreign-key columns.
create index if not exists stores_owner_id_idx on public.stores(owner_id);
create index if not exists addresses_customer_id_idx on public.addresses(customer_id);
create index if not exists orders_store_id_idx on public.orders(store_id);
create index if not exists orders_address_id_idx on public.orders(address_id);
create index if not exists order_items_order_id_idx on public.order_items(order_id);
create index if not exists order_items_product_id_idx on public.order_items(product_id);
create index if not exists order_events_actor_id_idx on public.order_events(actor_id);
