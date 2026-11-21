-- JIB: trusted checkout and role-escalation protection.
-- Delivery fee is a launch placeholder (15 MAD); replace with a server-side
-- zone/distance pricing model before operating commercially.

-- Prevent users from assigning themselves privileged roles at signup or later.
create or replace function public.guard_profile_role()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.role() is distinct from 'service_role' then
    if tg_op = 'INSERT' then
      new.role := 'customer';
    elsif new.role is distinct from old.role then
      raise exception 'Profile role changes require a privileged server operation';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_guard_role on public.profiles;
create trigger profiles_guard_role
before insert or update of role on public.profiles
for each row execute function public.guard_profile_role();

-- Checkout executes as one database transaction. Prices and product names are
-- always read from the database, never trusted from the client payload.
create or replace function public.checkout_order(
  p_store_id uuid,
  p_address_id uuid,
  p_items jsonb,
  p_customer_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_customer_id uuid := auth.uid();
  v_order_id uuid;
  v_subtotal numeric(10,2) := 0;
  v_delivery_fee numeric(10,2) := 15.00;
  v_item jsonb;
  v_product public.products%rowtype;
  v_quantity integer;
  v_count integer := 0;
begin
  if v_customer_id is null then
    raise exception 'Authentication required';
  end if;
  if p_store_id is null or p_address_id is null then
    raise exception 'Store and delivery address are required';
  end if;
  if jsonb_typeof(p_items) is distinct from 'array'
     or jsonb_array_length(p_items) < 1
     or jsonb_array_length(p_items) > 50 then
    raise exception 'Cart must contain between 1 and 50 items';
  end if;

  if not exists (
    select 1 from public.addresses a
    where a.id = p_address_id and a.customer_id = v_customer_id
  ) then
    raise exception 'Invalid delivery address';
  end if;
  if not exists (
    select 1 from public.stores s
    where s.id = p_store_id and s.is_active = true and s.is_open = true
  ) then
    raise exception 'Store is not accepting orders';
  end if;

  -- Validate every line and calculate totals from authoritative product prices.
  for v_item in select value from jsonb_array_elements(p_items)
  loop
    if coalesce(v_item->>'product_id','') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       or coalesce(v_item->>'quantity','') !~ '^[0-9]+$' then
      raise exception 'Invalid cart item';
    end if;
    v_quantity := (v_item->>'quantity')::integer;
    if v_quantity < 1 or v_quantity > 50 then
      raise exception 'Quantity must be between 1 and 50';
    end if;

    select * into v_product
    from public.products p
    where p.id = (v_item->>'product_id')::uuid
      and p.store_id = p_store_id
      and p.is_available = true;
    if not found then
      raise exception 'A product is unavailable';
    end if;

    v_subtotal := v_subtotal + (v_product.price_mad * v_quantity);
    v_count := v_count + 1;
  end loop;

  if v_count = 0 then
    raise exception 'Cart is empty';
  end if;

  insert into public.orders (
    customer_id, store_id, address_id, status, payment_method,
    payment_status, subtotal_mad, delivery_fee_mad, total_mad, customer_note
  ) values (
    v_customer_id, p_store_id, p_address_id, 'pending', 'cash',
    'pending', v_subtotal, v_delivery_fee, v_subtotal + v_delivery_fee,
    left(coalesce(p_customer_note,''), 1000)
  ) returning id into v_order_id;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_quantity := (v_item->>'quantity')::integer;
    select * into strict v_product
    from public.products p
    where p.id = (v_item->>'product_id')::uuid
      and p.store_id = p_store_id
      and p.is_available = true;

    insert into public.order_items (
      order_id, product_id, product_name_snapshot,
      unit_price_mad, quantity, line_total_mad
    ) values (
      v_order_id, v_product.id, v_product.name,
      v_product.price_mad, v_quantity, v_product.price_mad * v_quantity
    );
  end loop;

  insert into public.order_events(order_id, actor_id, status, note)
  values (v_order_id, v_customer_id, 'pending', 'Order placed');

  return v_order_id;
end;
$$;

revoke all on function public.checkout_order(uuid, uuid, jsonb, text) from public, anon;
grant execute on function public.checkout_order(uuid, uuid, jsonb, text) to authenticated;
