-- JIB production hardening and courier operations.
-- Role changes are permitted only through controlled self-enrollment RPCs.
create or replace function public.guard_profile_role()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
declare
  v_jwt_role text := coalesce((select auth.jwt() ->> 'role'), '');
  v_internal_change boolean :=
    coalesce(current_setting('jib.internal_profile_role_change', true), '') = 'true';
begin
  if v_jwt_role = 'service_role' then return new; end if;
  if tg_op = 'INSERT' then new.role := 'customer'; return new; end if;
  if new.role is distinct from old.role then
    if not (v_internal_change and (select auth.uid()) = new.id
      and old.role = 'customer' and new.role in ('merchant', 'courier')) then
      raise exception 'Profile role changes require a privileged enrollment operation';
    end if;
  end if;
  return new;
end;
$$;

create unique index if not exists stores_one_per_owner_idx on public.stores(owner_id);

create table if not exists public.courier_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  phone text,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  approved_at timestamptz,
  approved_by uuid references public.profiles(id)
);
alter table public.courier_profiles enable row level security;
revoke all on table public.courier_profiles from anon;
grant select on table public.courier_profiles to authenticated;
drop policy if exists courier_profiles_read_own on public.courier_profiles;
create policy courier_profiles_read_own on public.courier_profiles for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists courier_profiles_admin_read on public.courier_profiles;
create policy courier_profiles_admin_read on public.courier_profiles for select to authenticated
  using ((select public.is_jib_admin()));
create index if not exists courier_profiles_active_idx on public.courier_profiles(is_active, created_at desc);

create or replace function public.register_merchant_store(
  p_name text, p_category text, p_phone text default null, p_address text default null, p_description text default null
) returns uuid
language plpgsql security definer set search_path = pg_catalog, public, auth
as $$
declare v_uid uuid := (select auth.uid()); v_profile_role text; v_store_id uuid;
begin
  if v_uid is null then raise exception 'يجب تسجيل الدخول أولاً'; end if;
  if nullif(trim(coalesce(p_name, '')), '') is null then raise exception 'اسم المتجر مطلوب'; end if;
  if p_category not in ('restaurant', 'grocery', 'shop') then raise exception 'نوع المتجر غير صالح'; end if;
  select role into v_profile_role from public.profiles where id = v_uid for update;
  if not found then raise exception 'ملف المستخدم غير موجود'; end if;
  if v_profile_role not in ('customer', 'merchant') then raise exception 'هذا الحساب غير مؤهل للتسجيل كتاجر'; end if;
  select id into v_store_id from public.stores where owner_id = v_uid for update;
  if v_store_id is null then
    insert into public.stores(owner_id,name,category,phone,address_text,description,is_active,is_open)
    values(v_uid,trim(p_name),p_category,nullif(trim(coalesce(p_phone,'')),''),nullif(trim(coalesce(p_address,'')),''),
      nullif(trim(coalesce(p_description,'')),''),false,false) returning id into v_store_id;
  else
    update public.stores set name=trim(p_name),category=p_category,phone=nullif(trim(coalesce(p_phone,'')),''),
      address_text=nullif(trim(coalesce(p_address,'')),''),description=nullif(trim(coalesce(p_description,'')),''),
      updated_at=now() where id=v_store_id;
  end if;
  perform set_config('jib.internal_profile_role_change','true',true);
  update public.profiles set role='merchant',updated_at=now() where id=v_uid and role='customer';
  return v_store_id;
end;
$$;

create or replace function public.register_courier_profile(p_full_name text default null,p_phone text default null)
returns boolean
language plpgsql security definer set search_path = pg_catalog, public, auth
as $$
declare v_uid uuid := (select auth.uid()); v_profile_role text;
begin
  if v_uid is null then raise exception 'يجب تسجيل الدخول أولاً'; end if;
  select role into v_profile_role from public.profiles where id=v_uid for update;
  if not found then raise exception 'ملف المستخدم غير موجود'; end if;
  if v_profile_role not in ('customer','courier') then raise exception 'هذا الحساب لا يمكن تحويله إلى حساب مندوب'; end if;
  perform set_config('jib.internal_profile_role_change','true',true);
  update public.profiles set full_name=coalesce(nullif(trim(coalesce(p_full_name,'')),''),full_name),
    phone=coalesce(nullif(trim(coalesce(p_phone,'')),''),phone),role='courier',updated_at=now() where id=v_uid;
  insert into public.courier_profiles(user_id,phone) values(v_uid,nullif(trim(coalesce(p_phone,'')),''))
  on conflict(user_id) do update set phone=coalesce(excluded.phone,public.courier_profiles.phone);
  return true;
end;
$$;

create or replace function public.courier_dashboard()
returns table(order_id uuid,status text,total_mad numeric,delivery_fee_mad numeric,customer_note text,
  created_at timestamptz,store_name text,store_address text,delivery_address text)
language plpgsql security definer set search_path = pg_catalog, public, auth
as $$
declare v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'يجب تسجيل الدخول أولاً'; end if;
  if not exists(select 1 from public.profiles p join public.courier_profiles cp on cp.user_id=p.id
    where p.id=v_uid and p.role='courier' and cp.is_active=true) then
    raise exception 'حساب المندوب ينتظر اعتماد الإدارة';
  end if;
  return query select o.id,o.status,o.total_mad,o.delivery_fee_mad,
    case when o.courier_id=v_uid then o.customer_note else null end,o.created_at,s.name,s.address_text,
    case when o.courier_id=v_uid then a.address_text else null end
  from public.orders o join public.stores s on s.id=o.store_id left join public.addresses a on a.id=o.address_id
  where o.courier_id=v_uid or (o.courier_id is null and o.status='ready_for_pickup') order by o.created_at asc;
end;
$$;

create or replace function public.claim_delivery_order(p_order_id uuid)
returns boolean language plpgsql security definer set search_path = pg_catalog, public, auth
as $$
declare v_uid uuid := (select auth.uid()); v_rows integer;
begin
  if v_uid is null then raise exception 'يجب تسجيل الدخول أولاً'; end if;
  if not exists(select 1 from public.profiles p join public.courier_profiles cp on cp.user_id=p.id
    where p.id=v_uid and p.role='courier' and cp.is_active=true) then raise exception 'حساب المندوب غير معتمد أو غير نشط'; end if;
  update public.orders set courier_id=v_uid,updated_at=now()
  where id=p_order_id and status='ready_for_pickup' and courier_id is null;
  get diagnostics v_rows=row_count;
  if v_rows<>1 then raise exception 'الطلب لم يعد متاحاً لمندوب آخر'; end if;
  insert into public.order_events(order_id,actor_id,status,note)
  values(p_order_id,v_uid,'ready_for_pickup','Courier claimed delivery');
  return true;
end;
$$;

create or replace function public.courier_update_order_status(p_order_id uuid,p_new_status text)
returns void language plpgsql security definer set search_path = pg_catalog, public, auth
as $$
declare v_uid uuid := (select auth.uid()); v_old_status text;
begin
  if v_uid is null then raise exception 'يجب تسجيل الدخول أولاً'; end if;
  if p_new_status not in ('picked_up','delivering','delivered') then raise exception 'حالة الطلب غير صالحة'; end if;
  if not exists(select 1 from public.profiles p join public.courier_profiles cp on cp.user_id=p.id
    where p.id=v_uid and p.role='courier' and cp.is_active=true) then raise exception 'حساب المندوب غير معتمد أو غير نشط'; end if;
  select status into v_old_status from public.orders where id=p_order_id and courier_id=v_uid for update;
  if not found then raise exception 'الطلب غير مسند إلى حسابك'; end if;
  if not ((v_old_status='ready_for_pickup' and p_new_status='picked_up')
    or (v_old_status='picked_up' and p_new_status='delivering')
    or (v_old_status='delivering' and p_new_status='delivered')) then
    raise exception 'لا يمكن نقل الطلب من % إلى %',v_old_status,p_new_status;
  end if;
  update public.orders set status=p_new_status,updated_at=now() where id=p_order_id and courier_id=v_uid;
  insert into public.order_events(order_id,actor_id,status,note)
  values(p_order_id,v_uid,p_new_status,'Courier updated delivery status');
end;
$$;

create or replace function public.admin_set_courier_active(p_user_id uuid,p_active boolean)
returns void language plpgsql security definer set search_path = pg_catalog, public, auth
as $$
begin
  if (select auth.uid()) is null or not public.is_jib_admin() then raise exception 'صلاحية الإدارة مطلوبة'; end if;
  update public.courier_profiles set is_active=p_active,
    approved_at=case when p_active then now() else null end,
    approved_by=case when p_active then (select auth.uid()) else null end
  where user_id=p_user_id;
  if not found then raise exception 'طلب المندوب غير موجود'; end if;
end;
$$;

create or replace function public.admin_set_store_status(p_store_id uuid,p_is_active boolean,p_is_open boolean default false)
returns void language plpgsql security definer set search_path = pg_catalog, public, auth
as $$
begin
  if (select auth.uid()) is null or not public.is_jib_admin() then raise exception 'صلاحية الإدارة مطلوبة'; end if;
  update public.stores set is_active=p_is_active,is_open=(p_is_active and p_is_open),updated_at=now()
  where id=p_store_id;
  if not found then raise exception 'المتجر غير موجود'; end if;
end;
$$;

revoke all on function public.register_merchant_store(text,text,text,text,text) from public,anon;
revoke all on function public.merchant_update_order_status(uuid,text) from public,anon;
revoke all on function public.checkout_order(uuid,uuid,jsonb,text) from public,anon;
revoke all on function public.is_jib_admin() from public,anon;
revoke all on function public.register_courier_profile(text,text) from public,anon;
revoke all on function public.courier_dashboard() from public,anon;
revoke all on function public.claim_delivery_order(uuid) from public,anon;
revoke all on function public.courier_update_order_status(uuid,text) from public,anon;
revoke all on function public.admin_set_courier_active(uuid,boolean) from public,anon;
revoke all on function public.admin_set_store_status(uuid,boolean,boolean) from public,anon;
revoke all on function public.guard_profile_role() from public,anon,authenticated;
revoke all on function public.handle_new_auth_user() from public,anon,authenticated;

grant execute on function public.register_merchant_store(text,text,text,text,text) to authenticated;
grant execute on function public.merchant_update_order_status(uuid,text) to authenticated;
grant execute on function public.checkout_order(uuid,uuid,jsonb,text) to authenticated;
grant execute on function public.is_jib_admin() to authenticated;
grant execute on function public.register_courier_profile(text,text) to authenticated;
grant execute on function public.courier_dashboard() to authenticated;
grant execute on function public.claim_delivery_order(uuid) to authenticated;
grant execute on function public.courier_update_order_status(uuid,text) to authenticated;
grant execute on function public.admin_set_courier_active(uuid,boolean) to authenticated;
grant execute on function public.admin_set_store_status(uuid,boolean,boolean) to authenticated;
