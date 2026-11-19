-- JIB security hardening: disable direct client writes to financial order records.
-- Checkout must be implemented as a trusted server-side RPC/Edge Function that
-- re-reads product prices, validates store/address ownership and calculates totals.
-- Until that endpoint exists, customers cannot create orders from the client.

 drop policy if exists "orders_customer_create" on public.orders;
 drop policy if exists "order_items_customer_create" on public.order_items;

 revoke insert, update, delete on public.orders from anon, authenticated;
 revoke insert, update, delete on public.order_items from anon, authenticated;
 revoke insert, update, delete on public.order_events from anon, authenticated;

-- This intentionally makes checkout unavailable rather than exposing client-controlled
-- totals or order status changes. Add narrowly scoped server-side functions before launch.
