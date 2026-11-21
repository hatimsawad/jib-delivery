-- Customer checkout must independently enforce branch onboarding approval.
CREATE OR REPLACE FUNCTION public.checkout_order(p_store_id uuid, p_address_id uuid, p_items jsonb, p_customer_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
declare
  v_customer_id uuid := auth.uid();
  v_order_id uuid;
  v_subtotal numeric(10,2) := 0;
  v_delivery_fee numeric(10,2) := 15.00;
  v_item jsonb;
  v_product public.products%rowtype;
  v_quantity integer;
  v_count integer := 0;
  v_branch_policy_id uuid;
  v_fulfillment_mode text := 'courier_places_order';
  v_order_permission_status text := 'not_required';
  v_order_channel_url text;
  v_loyalty_mode text := 'none';
  v_loyalty_permission_status text := 'not_required';
  v_loyalty_program_name text;
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

  perform 1
  from public.stores s
  where s.id = p_store_id and s.is_active = true and s.is_open = true and s.onboarding_status = 'approved'
  for share;

  if not found then
    raise exception 'Store is not approved and open for customer orders';
  end if;

  select
    bp.id,
    bp.fulfillment_mode,
    bp.order_permission_status,
    bp.order_channel_url,
    bp.loyalty_mode,
    bp.loyalty_permission_status,
    bp.loyalty_program_name
  into
    v_branch_policy_id,
    v_fulfillment_mode,
    v_order_permission_status,
    v_order_channel_url,
    v_loyalty_mode,
    v_loyalty_permission_status,
    v_loyalty_program_name
  from public.store_branch_policies bp
  where bp.store_id = p_store_id
  for share;

  if not found then
    v_branch_policy_id := null;
    v_fulfillment_mode := 'courier_places_order';
    v_order_permission_status := 'not_required';
    v_order_channel_url := null;
    v_loyalty_mode := 'none';
    v_loyalty_permission_status := 'not_required';
    v_loyalty_program_name := null;
  end if;

  if v_fulfillment_mode <> 'courier_places_order'
     and v_order_permission_status <> 'approved' then
    raise exception 'This branch is not approved for JIB-managed ordering';
  end if;

  if v_fulfillment_mode = 'store_digital_order'
     and (
       v_order_channel_url is null
       or left(lower(v_order_channel_url), 8) <> 'https://'
       or v_order_channel_url ~ '[[:space:]]'
     ) then
    raise exception 'The branch official HTTPS ordering URL is missing or invalid';
  end if;

  if v_fulfillment_mode = 'partner_api_pos'
     and not exists (
       select 1
       from public.store_integrations si
       where si.store_id = p_store_id
         and si.status = 'connected'
         and si.integration_type in ('partner_api', 'pos')
     ) then
    raise exception 'The branch has no connected authorized API/POS integration';
  end if;

  if v_loyalty_mode in ('jib_business_account', 'partner_business_account')
     and (
       v_loyalty_permission_status <> 'approved'
       or nullif(trim(v_loyalty_program_name), '') is null
     ) then
    raise exception 'External loyalty collection is not approved for this branch';
  end if;

  -- Read authoritative prices and hold product rows stable until checkout commits.
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
      and p.is_available = true
    for share;

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
    payment_status, subtotal_mad, delivery_fee_mad, total_mad, customer_note,
    fulfillment_mode_snapshot, loyalty_mode_snapshot,
    loyalty_program_name_snapshot, branch_policy_id_snapshot
  ) values (
    v_customer_id, p_store_id, p_address_id, 'pending', 'cash',
    'pending', v_subtotal, v_delivery_fee, v_subtotal + v_delivery_fee,
    left(coalesce(p_customer_note,''), 1000),
    v_fulfillment_mode, v_loyalty_mode, v_loyalty_program_name, v_branch_policy_id
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
$function$;
