-- Branch-scoped order execution and loyalty permissions.
-- Each stores row represents one branch; policies are intentionally stored separately
-- and are visible/editable only to JIB administrators.
-- No external account credentials or payment secrets belong in this table.

create table if not exists public.store_branch_policies (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null unique references public.stores(id) on delete cascade,
  fulfillment_mode text not null default 'courier_places_order'
    check (fulfillment_mode in (
      'courier_places_order',
      'jib_central_order',
      'store_digital_order',
      'partner_api_pos'
    )),
  order_permission_status text not null default 'not_required'
    check (order_permission_status in (
      'not_required', 'pending', 'approved', 'rejected', 'suspended'
    )),
  order_channel_url text,
  order_permission_approved_at timestamptz,
  order_permission_approved_by uuid references auth.users(id) on delete set null,
  order_permission_reference text,
  loyalty_mode text not null default 'none'
    check (loyalty_mode in (
      'none', 'jib_business_account', 'partner_business_account', 'jib_rewards'
    )),
  loyalty_program_name text,
  loyalty_permission_status text not null default 'not_required'
    check (loyalty_permission_status in (
      'not_required', 'pending', 'approved', 'rejected', 'suspended'
    )),
  loyalty_permission_approved_at timestamptz,
  loyalty_permission_approved_by uuid references auth.users(id) on delete set null,
  loyalty_permission_reference text,
  operator_notes text,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint store_branch_policies_order_permission_required_check
    check (
      fulfillment_mode = 'courier_places_order'
      or order_permission_status <> 'not_required'
    ),
  constraint store_branch_policies_loyalty_permission_required_check
    check (
      loyalty_mode not in ('jib_business_account', 'partner_business_account')
      or loyalty_permission_status <> 'not_required'
    ),
  constraint store_branch_policies_order_approval_evidence_check
    check (
      order_permission_status <> 'approved'
      or (
        order_permission_approved_at is not null
        and order_permission_approved_by is not null
        and nullif(trim(order_permission_reference), '') is not null
      )
    ),
  constraint store_branch_policies_online_url_check
    check (
      fulfillment_mode <> 'store_digital_order'
      or order_permission_status <> 'approved'
      or order_channel_url ~ '^https://[^[:space:]]+
  constraint store_branch_policies_loyalty_approval_evidence_check
    check (
      loyalty_permission_status <> 'approved'
      or (
        loyalty_permission_approved_at is not null
        and loyalty_permission_approved_by is not null
        and nullif(trim(loyalty_permission_reference), '') is not null
      )
    ),
  constraint store_branch_policies_external_loyalty_permission_check
    check (
      loyalty_mode not in ('jib_business_account', 'partner_business_account')
      or loyalty_permission_status <> 'approved'
      or nullif(trim(loyalty_program_name), '') is not null
    ),
  constraint store_branch_policies_urls_check
    check (
      order_channel_url is null
      or order_channel_url ~ '^https://[^[:space:]]+$'
    )
);

create index if not exists store_branch_policies_fulfillment_mode_idx
  on public.store_branch_policies(fulfillment_mode, order_permission_status);
create index if not exists store_branch_policies_loyalty_mode_idx
  on public.store_branch_policies(loyalty_mode, loyalty_permission_status);

alter table public.store_branch_policies enable row level security;

drop policy if exists store_branch_policies_admin_all on public.store_branch_policies;
create policy store_branch_policies_admin_all
  on public.store_branch_policies
  for all to authenticated
  using ((select public.is_jib_admin()))
  with check ((select public.is_jib_admin()));

-- New public-schema tables are not automatically exposed through the Data API
-- on current Supabase projects; grant authenticated access and let RLS restrict
-- every operation to JIB administrators. No anonymous access is granted.
revoke all privileges on table public.store_branch_policies from anon, public;
grant select, insert, update, delete on table public.store_branch_policies to authenticated;

alter table public.orders
  add column if not exists fulfillment_mode_snapshot text not null default 'courier_places_order'
    check (fulfillment_mode_snapshot in (
      'courier_places_order', 'jib_central_order', 'store_digital_order', 'partner_api_pos'
    )),
  add column if not exists loyalty_mode_snapshot text not null default 'none'
    check (loyalty_mode_snapshot in (
      'none', 'jib_business_account', 'partner_business_account', 'jib_rewards'
    )),
  add column if not exists loyalty_program_name_snapshot text,
  add column if not exists branch_policy_id_snapshot uuid;

create index if not exists orders_fulfillment_mode_created_idx
  on public.orders(fulfillment_mode_snapshot, created_at desc);

-- Keep the trusted checkout as the only order-creation path. The selected branch
-- policy is read inside the transaction and copied to the order as immutable context.
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
  if not exists (
    select 1 from public.stores s
    where s.id = p_store_id and s.is_active = true and s.is_open = true
  ) then
    raise exception 'Store is not accepting orders';
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
  where bp.store_id = p_store_id;

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
     and v_order_channel_url is null then
    raise exception 'The branch official online order URL is missing';
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
$$;

revoke all on function public.checkout_order(uuid, uuid, jsonb, text) from public, anon;
grant execute on function public.checkout_order(uuid, uuid, jsonb, text) to authenticated;

comment on table public.store_branch_policies is
  'Admin-only operational settings per individual store branch. Permission approval is branch-specific; credentials are never stored here.';
comment on column public.orders.fulfillment_mode_snapshot is
  'Branch execution method captured at checkout so later branch policy edits do not alter an existing order.';
comment on column public.orders.loyalty_mode_snapshot is
  'Branch loyalty policy captured at checkout; it does not itself claim that external points were awarded.';

    ),
  constraint store_branch_policies_external_loyalty_permission_check
    check (
      loyalty_mode not in ('jib_business_account', 'partner_business_account')
      or (
        loyalty_permission_status = 'approved'
        and nullif(trim(loyalty_program_name), '') is not null
      )
    ),
  constraint store_branch_policies_urls_check
    check (
      order_channel_url is null
      or order_channel_url ~ '^https://[^[:space:]]+$'
    )
);

create index if not exists store_branch_policies_fulfillment_mode_idx
  on public.store_branch_policies(fulfillment_mode, order_permission_status);
create index if not exists store_branch_policies_loyalty_mode_idx
  on public.store_branch_policies(loyalty_mode, loyalty_permission_status);

alter table public.store_branch_policies enable row level security;

drop policy if exists store_branch_policies_admin_all on public.store_branch_policies;
create policy store_branch_policies_admin_all
  on public.store_branch_policies
  for all to authenticated
  using ((select public.is_jib_admin()))
  with check ((select public.is_jib_admin()));

-- New public-schema tables are not automatically exposed through the Data API
-- on current Supabase projects; grant authenticated access and let RLS restrict
-- every operation to JIB administrators. No anonymous access is granted.
revoke all privileges on table public.store_branch_policies from anon, public;
grant select, insert, update, delete on table public.store_branch_policies to authenticated;

alter table public.orders
  add column if not exists fulfillment_mode_snapshot text not null default 'courier_places_order'
    check (fulfillment_mode_snapshot in (
      'courier_places_order', 'jib_central_order', 'store_digital_order', 'partner_api_pos'
    )),
  add column if not exists loyalty_mode_snapshot text not null default 'none'
    check (loyalty_mode_snapshot in (
      'none', 'jib_business_account', 'partner_business_account', 'jib_rewards'
    )),
  add column if not exists loyalty_program_name_snapshot text,
  add column if not exists branch_policy_id_snapshot uuid;

create index if not exists orders_fulfillment_mode_created_idx
  on public.orders(fulfillment_mode_snapshot, created_at desc);

-- Keep the trusted checkout as the only order-creation path. The selected branch
-- policy is read inside the transaction and copied to the order as immutable context.
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
  if not exists (
    select 1 from public.stores s
    where s.id = p_store_id and s.is_active = true and s.is_open = true
  ) then
    raise exception 'Store is not accepting orders';
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
  where bp.store_id = p_store_id;

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
     and v_order_channel_url is null then
    raise exception 'The branch official online order URL is missing';
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
$$;

revoke all on function public.checkout_order(uuid, uuid, jsonb, text) from public, anon;
grant execute on function public.checkout_order(uuid, uuid, jsonb, text) to authenticated;

comment on table public.store_branch_policies is
  'Admin-only operational settings per individual store branch. Permission approval is branch-specific; credentials are never stored here.';
comment on column public.orders.fulfillment_mode_snapshot is
  'Branch execution method captured at checkout so later branch policy edits do not alter an existing order.';
comment on column public.orders.loyalty_mode_snapshot is
  'Branch loyalty policy captured at checkout; it does not itself claim that external points were awarded.';
