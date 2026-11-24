-- Direct-purchase ordering and courier cash settlement for JIB V2.
-- Applied to the isolated JIB V2 Supabase project; no legacy tables are touched.

alter table public.merchants alter column owner_user_id drop not null;
alter table public.merchants add column if not exists brand_id uuid references public.brands(id);
alter table public.merchants add column if not exists is_direct_purchase boolean not null default false;
create unique index if not exists merchants_direct_purchase_brand_uidx
  on public.merchants(brand_id) where is_direct_purchase = true and brand_id is not null;

alter table public.order_items alter column branch_product_id drop not null;
alter table public.order_items add column if not exists product_id uuid references public.products(id);
alter table public.order_items add constraint order_items_product_source_check
  check (branch_product_id is not null or product_id is not null);

alter table public.orders add column if not exists delivery_fee_mad numeric(12,2);
alter table public.orders add column if not exists courier_purchase_total_mad numeric(12,2);
alter table public.orders add column if not exists customer_cash_collected_mad numeric(12,2);
alter table public.orders add column if not exists courier_cash_handed_at timestamptz;
alter table public.orders add column if not exists courier_fee_paid_at timestamptz;
alter table public.orders add constraint orders_delivery_fee_nonnegative_check
  check (delivery_fee_mad is null or delivery_fee_mad >= 0);
alter table public.orders add constraint orders_purchase_total_nonnegative_check
  check (courier_purchase_total_mad is null or courier_purchase_total_mad >= 0);
alter table public.orders add constraint orders_cash_collected_nonnegative_check
  check (customer_cash_collected_mad is null or customer_cash_collected_mad >= 0);

create or replace function private.submit_purchase_order(
  p_branch_id uuid,
  p_delivery_address text,
  p_customer_phone text,
  p_items jsonb,
  p_customer_note text default null,
  p_delivery_latitude double precision default null,
  p_delivery_longitude double precision default null
) returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_brand_id uuid;
  v_order_id uuid;
  v_valid_count integer;
  v_item_count integer;
  v_subtotal numeric(12,2);
begin
  if v_user_id is null or not private.has_role(v_user_id,'customer') then
    raise exception 'حساب الزبون مطلوب لإرسال طلب شراء';
  end if;
  if coalesce(length(trim(p_delivery_address)),0) < 5 then raise exception 'عنوان التوصيل غير مكتمل'; end if;
  if coalesce(length(trim(p_customer_phone)),0) < 8 then raise exception 'رقم الهاتف غير صالح'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items)=0 then
    raise exception 'أضف منتجاً واحداً على الأقل';
  end if;
  if jsonb_array_length(p_items)>30 then raise exception 'عدد المنتجات يتجاوز الحد المسموح'; end if;
  if exists (
    select 1 from jsonb_to_recordset(p_items) as i(product_id uuid, quantity integer)
    where i.product_id is null or i.quantity is null or i.quantity<1 or i.quantity>50
  ) then raise exception 'بيانات المنتج أو الكمية غير صالحة'; end if;
  if (select count(*) from jsonb_to_recordset(p_items) as i(product_id uuid, quantity integer))
    <> (select count(distinct product_id) from jsonb_to_recordset(p_items) as i(product_id uuid, quantity integer))
  then raise exception 'لا تكرر المنتج في السلة'; end if;

  select m.brand_id into v_brand_id
  from public.branches b
  join public.merchants m on m.id=b.merchant_id
  where b.id=p_branch_id and b.is_active=true and m.is_active=true
    and m.is_direct_purchase=true and b.city='Rabat';
  if not found or v_brand_id is null then raise exception 'متجر الشراء غير مفعّل في الرباط'; end if;

  select count(*),
         coalesce(sum(
           (case
             when strpos(lower(coalesce(p.reference_notes,'')),'(+2 mad)')>0
               or strpos(lower(coalesce(p.reference_notes,'')),'jib reference price')>0
               or strpos(lower(coalesce(p.reference_notes,'')),'سعر jib المرجعي')>0
               or strpos(lower(coalesce(p.reference_notes,'')),'السعر المرجعي + 2')>0
               or strpos(lower(coalesce(p.reference_notes,'')),'السعر المرجعي التاريخي + 2')>0
             then p.reference_price_mad
             else p.reference_price_mad + 2
           end) * i.quantity
         ),0)
    into v_valid_count,v_subtotal
  from jsonb_to_recordset(p_items) as i(product_id uuid, quantity integer)
  join public.products p on p.id=i.product_id
  join public.brands br on br.id=p.brand_id
  where p.is_active=true and p.brand_id=v_brand_id
    and p.reference_price_mad is not null
    and br.is_active=true and br.is_approved=true;

  select count(*) into v_item_count
  from jsonb_to_recordset(p_items) as i(product_id uuid, quantity integer);
  if v_valid_count<>v_item_count then
    raise exception 'بعض المنتجات لا تملك سعراً مرجعياً مؤكداً لهذا المتجر';
  end if;

  insert into public.orders(
    customer_id,branch_id,delivery_address,customer_phone,customer_note,
    delivery_latitude,delivery_longitude,subtotal_mad,status,submitted_at
  ) values (
    v_user_id,p_branch_id,trim(p_delivery_address),trim(p_customer_phone),
    nullif(trim(coalesce(p_customer_note,'')),''),
    p_delivery_latitude,p_delivery_longitude,v_subtotal,'customer_submitted',now()
  ) returning id into v_order_id;

  insert into public.order_items(
    order_id,branch_product_id,product_id,product_name_snapshot,unit_price_mad,quantity,line_total_mad
  )
  select v_order_id,null,p.id,p.name,
    case
      when strpos(lower(coalesce(p.reference_notes,'')),'(+2 mad)')>0
        or strpos(lower(coalesce(p.reference_notes,'')),'jib reference price')>0
        or strpos(lower(coalesce(p.reference_notes,'')),'سعر jib المرجعي')>0
        or strpos(lower(coalesce(p.reference_notes,'')),'السعر المرجعي + 2')>0
        or strpos(lower(coalesce(p.reference_notes,'')),'السعر المرجعي التاريخي + 2')>0
      then p.reference_price_mad
      else p.reference_price_mad+2
    end,
    i.quantity,
    (case
      when strpos(lower(coalesce(p.reference_notes,'')),'(+2 mad)')>0
        or strpos(lower(coalesce(p.reference_notes,'')),'jib reference price')>0
        or strpos(lower(coalesce(p.reference_notes,'')),'سعر jib المرجعي')>0
        or strpos(lower(coalesce(p.reference_notes,'')),'السعر المرجعي + 2')>0
        or strpos(lower(coalesce(p.reference_notes,'')),'السعر المرجعي التاريخي + 2')>0
      then p.reference_price_mad
      else p.reference_price_mad+2
    end) * i.quantity
  from jsonb_to_recordset(p_items) as i(product_id uuid, quantity integer)
  join public.products p on p.id=i.product_id
  where p.brand_id=v_brand_id and p.is_active=true;

  insert into public.order_events(order_id,actor_user_id,from_status,to_status,reason)
  values(v_order_id,v_user_id,null,'customer_submitted','طلب شراء مباشر؛ المندوب يشتري المنتجات من المتجر');
  return v_order_id;
end;
$function$;

create or replace function public.submit_purchase_order(
  p_branch_id uuid,
  p_delivery_address text,
  p_customer_phone text,
  p_items jsonb,
  p_customer_note text default null,
  p_delivery_latitude double precision default null,
  p_delivery_longitude double precision default null
) returns uuid
language plpgsql
set search_path to ''
as $function$
begin
  return private.submit_purchase_order(
    p_branch_id,p_delivery_address,p_customer_phone,p_items,
    p_customer_note,p_delivery_latitude,p_delivery_longitude
  );
end;
$function$;
revoke all on function public.submit_purchase_order(uuid,text,text,jsonb,text,double precision,double precision) from public,anon;
grant execute on function public.submit_purchase_order(uuid,text,text,jsonb,text,double precision,double precision) to authenticated;
grant execute on function private.submit_purchase_order(uuid,text,text,jsonb,text,double precision,double precision) to authenticated;

create or replace function private.admin_set_order_delivery_fee(p_order_id uuid,p_fee_mad numeric)
returns numeric
language plpgsql
security definer
set search_path to ''
as $function$
declare v_fee numeric(12,2);
begin
  if auth.uid() is null or not private.has_role(auth.uid(),'admin') then raise exception 'صلاحية الإدارة مطلوبة'; end if;
  if p_fee_mad is null or p_fee_mad<0 then raise exception 'رسوم التوصيل غير صالحة'; end if;
  update public.orders set delivery_fee_mad=round(p_fee_mad,2),updated_at=now()
    where id=p_order_id and status='customer_submitted'
    returning delivery_fee_mad into v_fee;
  if not found then raise exception 'لا يمكن تعديل رسوم هذا الطلب في حالته الحالية'; end if;
  insert into public.order_events(order_id,actor_user_id,from_status,to_status,reason)
  values(p_order_id,auth.uid(),'customer_submitted','customer_submitted','تحديد رسوم التوصيل حسب المسافة');
  return v_fee;
end;
$function$;

create or replace function public.admin_set_order_delivery_fee(p_order_id uuid,p_fee_mad numeric)
returns numeric
language sql
set search_path to ''
as $function$
  select private.admin_set_order_delivery_fee(p_order_id,p_fee_mad);
$function$;
revoke all on function public.admin_set_order_delivery_fee(uuid,numeric) from public,anon;
grant execute on function public.admin_set_order_delivery_fee(uuid,numeric) to authenticated;

create or replace function private.admin_offer_courier(p_order_id uuid,p_courier_id uuid)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user_id uuid:=auth.uid();
  v_order public.orders%rowtype;
  v_assignment_id uuid;
  v_direct_purchase boolean;
begin
  if v_user_id is null or not private.has_role(v_user_id,'admin') then raise exception 'صلاحية الإدارة مطلوبة'; end if;
  if not exists (
    select 1 from public.profiles p
    join public.courier_profiles cp on cp.user_id=p.id
    where p.id=p_courier_id and p.role='courier' and cp.is_on_duty=true
  ) then raise exception 'المندوب غير متاح أو لم يفعّل وضع العمل'; end if;

  select * into v_order from public.orders where id=p_order_id for update;
  if not found then raise exception 'الطلب غير موجود'; end if;

  select m.is_direct_purchase into v_direct_purchase
  from public.branches b join public.merchants m on m.id=b.merchant_id
  where b.id=v_order.branch_id;

  if v_order.status not in ('customer_submitted','ready_for_pickup','courier_offered') then
    raise exception 'الطلب غير جاهز لإسناد مندوب';
  end if;
  if v_direct_purchase=true and v_order.delivery_fee_mad is null then
    raise exception 'حدد رسوم التوصيل قبل إسناد المندوب';
  end if;

  insert into public.courier_assignments(order_id,courier_id,status,offered_at)
  values(p_order_id,p_courier_id,'offered',now())
  on conflict(order_id,courier_id) do update
    set status='offered',offered_at=now(),responded_at=null
  returning id into v_assignment_id;

  update public.orders set status='courier_offered',courier_offered_at=now(),updated_at=now()
  where id=p_order_id;
  insert into public.order_events(order_id,actor_user_id,from_status,to_status,reason)
  values(p_order_id,v_user_id,v_order.status,'courier_offered','تم إرسال عرض الشراء والتوصيل إلى المندوب');
  return v_assignment_id;
end;
$function$;

create or replace function private.courier_confirm_purchase(p_order_id uuid,p_purchase_total_mad numeric)
returns text
language plpgsql
security definer
set search_path to ''
as $function$
declare v_order public.orders%rowtype;
begin
  if auth.uid() is null then raise exception 'يلزم تسجيل الدخول'; end if;
  if p_purchase_total_mad is null or p_purchase_total_mad<0 then raise exception 'قيمة الشراء غير صالحة'; end if;
  if not exists(select 1 from public.courier_assignments
    where order_id=p_order_id and courier_id=auth.uid() and status='accepted') then
    raise exception 'لا يوجد إسناد مقبول لهذا الطلب';
  end if;
  select * into v_order from public.orders where id=p_order_id for update;
  if not found or v_order.status<>'courier_accepted' then raise exception 'حالة الطلب لا تسمح بتسجيل الشراء'; end if;
  update public.orders set status='picked_up',picked_up_at=now(),
    courier_purchase_total_mad=round(p_purchase_total_mad,2),updated_at=now()
    where id=p_order_id;
  insert into public.order_events(order_id,actor_user_id,from_status,to_status,reason)
  values(p_order_id,auth.uid(),'courier_accepted','picked_up',
    'اشترى المندوب المنتجات من المتجر؛ تكلفة الشراء الفعلية: '||round(p_purchase_total_mad,2)::text||' MAD');
  return 'picked_up';
end;
$function$;

create or replace function public.courier_confirm_purchase(p_order_id uuid,p_purchase_total_mad numeric)
returns text
language sql
set search_path to ''
as $function$
  select private.courier_confirm_purchase(p_order_id,p_purchase_total_mad);
$function$;
revoke all on function public.courier_confirm_purchase(uuid,numeric) from public,anon;
grant execute on function public.courier_confirm_purchase(uuid,numeric) to authenticated;

create or replace function private.courier_complete_delivery(p_order_id uuid,p_cash_collected_mad numeric)
returns text
language plpgsql
security definer
set search_path to ''
as $function$
declare v_order public.orders%rowtype;
begin
  if auth.uid() is null then raise exception 'يلزم تسجيل الدخول'; end if;
  if p_cash_collected_mad is null or p_cash_collected_mad<0 then raise exception 'المبلغ المحصل غير صالح'; end if;
  if not exists(select 1 from public.courier_assignments
    where order_id=p_order_id and courier_id=auth.uid() and status='accepted') then
    raise exception 'لا يوجد إسناد مقبول لهذا الطلب';
  end if;
  select * into v_order from public.orders where id=p_order_id for update;
  if not found or v_order.status<>'en_route' then raise exception 'حالة الطلب لا تسمح بتأكيد التسليم'; end if;
  if v_order.courier_purchase_total_mad is null then raise exception 'سجّل تكلفة شراء المنتجات أولاً'; end if;
  update public.orders set status='delivered',delivered_at=now(),
    customer_cash_collected_mad=round(p_cash_collected_mad,2),updated_at=now()
    where id=p_order_id;
  update public.courier_assignments set status='completed'
    where order_id=p_order_id and courier_id=auth.uid();
  insert into public.order_events(order_id,actor_user_id,from_status,to_status,reason)
  values(p_order_id,auth.uid(),'en_route','delivered',
    'تم التسليم وتحصيل '||round(p_cash_collected_mad,2)::text||' MAD نقداً');
  return 'delivered';
end;
$function$;

create or replace function public.courier_complete_delivery(p_order_id uuid,p_cash_collected_mad numeric)
returns text
language sql
set search_path to ''
as $function$
  select private.courier_complete_delivery(p_order_id,p_cash_collected_mad);
$function$;
revoke all on function public.courier_complete_delivery(uuid,numeric) from public,anon;
grant execute on function public.courier_complete_delivery(uuid,numeric) to authenticated;

create or replace function private.admin_mark_courier_cash_handed(p_order_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path to ''
as $function$
declare v_time timestamptz;
begin
  if auth.uid() is null or not private.has_role(auth.uid(),'admin') then raise exception 'صلاحية الإدارة مطلوبة'; end if;
  update public.orders set courier_cash_handed_at=now(),updated_at=now()
  where id=p_order_id and status='delivered'
    and customer_cash_collected_mad is not null and courier_purchase_total_mad is not null
    and courier_cash_handed_at is null
  returning courier_cash_handed_at into v_time;
  if not found then raise exception 'لا يوجد مبلغ مستحق للتحصيل أو سبق تسجيل التحصيل'; end if;
  return v_time;
end;
$function$;

create or replace function public.admin_mark_courier_cash_handed(p_order_id uuid)
returns timestamptz
language sql
set search_path to ''
as $function$
  select private.admin_mark_courier_cash_handed(p_order_id);
$function$;
revoke all on function public.admin_mark_courier_cash_handed(uuid) from public,anon;
grant execute on function public.admin_mark_courier_cash_handed(uuid) to authenticated;

create or replace function private.admin_mark_courier_fee_paid(p_order_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path to ''
as $function$
declare v_time timestamptz;
begin
  if auth.uid() is null or not private.has_role(auth.uid(),'admin') then raise exception 'صلاحية الإدارة مطلوبة'; end if;
  update public.orders set courier_fee_paid_at=now(),updated_at=now()
  where id=p_order_id and status='delivered'
    and delivery_fee_mad is not null
    and delivered_at<=now()-interval '15 days'
    and courier_cash_handed_at is not null
    and courier_fee_paid_at is null
  returning courier_fee_paid_at into v_time;
  if not found then raise exception 'مستحقات المندوب لم يحل موعدها أو لم يتم تحصيل المبلغ الأسبوعي بعد'; end if;
  return v_time;
end;
$function$;

create or replace function public.admin_mark_courier_fee_paid(p_order_id uuid)
returns timestamptz
language sql
set search_path to ''
as $function$
  select private.admin_mark_courier_fee_paid(p_order_id);
$function$;
revoke all on function public.admin_mark_courier_fee_paid(uuid) from public,anon;
grant execute on function public.admin_mark_courier_fee_paid(uuid) to authenticated;
