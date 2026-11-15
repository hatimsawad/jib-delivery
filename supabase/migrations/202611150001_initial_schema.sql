-- JIB initial schema for Supabase PostgreSQL
-- Apply through Supabase migrations after the project is connected.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role text not null default 'customer'
    check (role in ('customer', 'courier', 'merchant', 'admin')),
  preferred_language text not null default 'ar'
    check (preferred_language in ('ar', 'fr')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id),
  name text not null,
  description text,
  category text not null
    check (category in ('restaurant', 'grocery', 'shop')),
  phone text,
  address_text text,
  latitude double precision,
  longitude double precision,
  is_active boolean not null default false,
  is_open boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null,
  description text,
  price_mad numeric(10,2) not null check (price_mad >= 0),
  image_url text,
  is_available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id) on delete cascade,
  label text not null default 'Home',
  address_text text not null,
  latitude double precision,
  longitude double precision,
  delivery_notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id),
  store_id uuid not null references public.stores(id),
  courier_id uuid references auth.users(id),
  address_id uuid references public.addresses(id),
  status text not null default 'pending'
    check (status in (
      'pending', 'accepted', 'rejected', 'preparing',
      'ready_for_pickup', 'picked_up', 'delivering',
      'delivered', 'cancelled'
    )),
  payment_method text not null default 'cash'
    check (payment_method in ('cash')),
  payment_status text not null default 'pending'
    check (payment_status in ('pending', 'paid', 'failed', 'refunded')),
  subtotal_mad numeric(10,2) not null check (subtotal_mad >= 0),
  delivery_fee_mad numeric(10,2) not null default 0 check (delivery_fee_mad >= 0),
  total_mad numeric(10,2) not null check (total_mad >= 0),
  customer_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name_snapshot text not null,
  unit_price_mad numeric(10,2) not null check (unit_price_mad >= 0),
  quantity integer not null check (quantity > 0),
  line_total_mad numeric(10,2) not null check (line_total_mad >= 0)
);

create table if not exists public.order_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  actor_id uuid references auth.users(id),
  status text not null,
  note text,
  created_at timestamptz not null default now()
);

create index if not exists stores_category_active_idx
  on public.stores(category, is_active, is_open);
create index if not exists products_store_available_idx
  on public.products(store_id, is_available);
create index if not exists orders_customer_created_idx
  on public.orders(customer_id, created_at desc);
create index if not exists orders_courier_status_idx
  on public.orders(courier_id, status);
create index if not exists order_events_order_created_idx
  on public.order_events(order_id, created_at);

alter table public.profiles enable row level security;
alter table public.stores enable row level security;
alter table public.products enable row level security;
alter table public.addresses enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_events enable row level security;

-- Profiles: users can read and update only their own profile.
create policy "profiles_read_own"
  on public.profiles for select to authenticated
  using (id = auth.uid());
create policy "profiles_insert_own"
  on public.profiles for insert to authenticated
  with check (id = auth.uid());
create policy "profiles_update_own"
  on public.profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Active stores and available products are visible to signed-in customers.
create policy "stores_read_active"
  on public.stores for select to authenticated
  using (is_active = true or owner_id = auth.uid());
create policy "stores_owner_manage"
  on public.stores for all to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "products_read_available"
  on public.products for select to authenticated
  using (
    is_available = true
    and exists (
      select 1 from public.stores s
      where s.id = store_id and s.is_active = true
    )
    or exists (
      select 1 from public.stores s
      where s.id = store_id and s.owner_id = auth.uid()
    )
  );
create policy "products_owner_manage"
  on public.products for all to authenticated
  using (
    exists (select 1 from public.stores s
      where s.id = store_id and s.owner_id = auth.uid())
  )
  with check (
    exists (select 1 from public.stores s
      where s.id = store_id and s.owner_id = auth.uid())
  );

create policy "addresses_owner_manage"
  on public.addresses for all to authenticated
  using (customer_id = auth.uid())
  with check (customer_id = auth.uid());

create policy "orders_customer_read"
  on public.orders for select to authenticated
  using (customer_id = auth.uid());
create policy "orders_customer_create"
  on public.orders for insert to authenticated
  with check (customer_id = auth.uid());
create policy "orders_store_owner_read"
  on public.orders for select to authenticated
  using (exists (select 1 from public.stores s
    where s.id = store_id and s.owner_id = auth.uid()));
create policy "orders_assigned_courier_read"
  on public.orders for select to authenticated
  using (courier_id = auth.uid());

create policy "order_items_participant_read"
  on public.order_items for select to authenticated
  using (exists (select 1 from public.orders o
    where o.id = order_id
      and (o.customer_id = auth.uid() or o.courier_id = auth.uid()
        or exists (select 1 from public.stores s
          where s.id = o.store_id and s.owner_id = auth.uid()))));
create policy "order_items_customer_create"
  on public.order_items for insert to authenticated
  with check (exists (select 1 from public.orders o
    where o.id = order_id and o.customer_id = auth.uid()));

create policy "order_events_participant_read"
  on public.order_events for select to authenticated
  using (exists (select 1 from public.orders o
    where o.id = order_id
      and (o.customer_id = auth.uid() or o.courier_id = auth.uid()
        or exists (select 1 from public.stores s
          where s.id = o.store_id and s.owner_id = auth.uid()))));
