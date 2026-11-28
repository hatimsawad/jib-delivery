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
    select 1 from jsonb_to_recordset(p_items) as i(product_id uuid, quantity integer, expected_unit_price_mad numeric)
    where i.product_id is null or i.quantity is null or i.quantity<1 or i.quantity>50
      or i.expected_unit_price_mad is null or i.expected_unit_price_mad<0
  ) then raise exception 'بيانات المنتج أو الكمية أو السعر المتوقع غير صالحة'; end if;
  if (select count(*) from jsonb_to_recordset(p_items) as i(product_id uuid, quantity integer, expected_unit_price_mad numeric))
    <> (select count(distinct product_id) from jsonb_to_recordset(p_items) as i(product_id uuid, quantity integer, expected_unit_price_mad numeric))
  then raise exception 'لا تكرر المنتج في السلة'; end if;

  select m.brand_id into v_brand_id
  from public.branches b
  join public.merchants m on m.id=b.merchant_id
  where b.id=p_branch_id and b.is_active=true and m.is_active=true
    and m.is_direct_purchase=true and b.city='Rabat';
  if not found or v_brand_id is null then raise exception 'متجر الشراء غير مفعّل في الرباط'; end if;

  select count(*), coalesce(sum(bp.price_mad * i.quantity),0)
    into v_valid_count,v_subtotal
  from jsonb_to_recordset(p_items) as i(product_id uuid, quantity integer, expected_unit_price_mad numeric)
  join public.products p on p.id=i.product_id
  join public.brands br on br.id=p.brand_id
  join public.branch_products bp on bp.product_id=p.id and bp.branch_id=p_branch_id
  where p.is_active=true and p.brand_id=v_brand_id
    and p.category = any(array[
      'food','grocery','drinks','dairy','meat','produce','bakery','frozen-food',
      'breakfast','burgers','desserts','prepared-food','menus','fries','sauces','sharing',
      'wraps','mccafe','happy-meal','menu-mabrouk','duo-mabrouk',
      'moroccan-breakfast','salads'
    ]::text[])
    and br.is_active=true and br.is_approved=true
    and bp.is_active=true and bp.availability='available'
    and bp.confirmed_at is not null and bp.price_mad is not null
    and bp.price_mad=i.expected_unit_price_mad;

  select count(*) into v_item_count
  from jsonb_to_recordset(p_items) as i(product_id uuid, quantity integer, expected_unit_price_mad numeric);
  if v_valid_count<>v_item_count then
    raise exception 'تغير السعر أو لم يؤكد الفرع توفر بعض المنتجات؛ حدّث السلة قبل إعادة الطلب';
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
  select v_order_id,bp.id,p.id,p.name,bp.price_mad,i.quantity,bp.price_mad*i.quantity
  from jsonb_to_recordset(p_items) as i(product_id uuid, quantity integer, expected_unit_price_mad numeric)
  join public.products p on p.id=i.product_id
  join public.branch_products bp on bp.product_id=p.id and bp.branch_id=p_branch_id
  where p.brand_id=v_brand_id and p.is_active=true
    and bp.is_active=true and bp.availability='available'
    and bp.confirmed_at is not null and bp.price_mad=i.expected_unit_price_mad;

  insert into public.order_events(order_id,actor_user_id,from_status,to_status,reason)
  values(v_order_id,v_user_id,null,'customer_submitted','طلب شراء مباشر؛ السعر والتوفر مؤكدان من فرع الشراء');
  return v_order_id;
end;
$function$;

create or replace function private.merchant_update_order(
  p_order_id uuid,
  p_action text,
  p_reason text default null,
  p_eta_minutes integer default null
) returns text
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_order public.orders%rowtype;
  v_new_status text;
begin
  if v_user_id is null then raise exception 'يلزم تسجيل الدخول'; end if;
  if p_action not in ('accept','reject','start_preparing','mark_ready') then raise exception 'إجراء غير صالح'; end if;
  if p_eta_minutes is not null and p_eta_minutes < 0 then raise exception 'الوقت المتوقع غير صالح'; end if;
  if p_action='reject' and length(trim(coalesce(p_reason,''))) < 5 then
    raise exception 'اكتب سبباً واضحاً لرفض الطلب (5 أحرف على الأقل)';
  end if;

  select o.* into v_order
  from public.orders o
  join public.branches b on b.id=o.branch_id
  join public.merchants m on m.id=b.merchant_id
  where o.id=p_order_id and m.owner_user_id=v_user_id
  for update of o;
  if not found then raise exception 'الطلب غير موجود أو لا تملك صلاحية إدارته'; end if;

  if p_action='accept' and v_order.status='customer_submitted' then
    v_new_status := 'merchant_accepted';
    update public.orders set status=v_new_status,merchant_accepted_at=now(),
      eta_minutes=coalesce(p_eta_minutes,eta_minutes),
      eta_updated_at=case when p_eta_minutes is null then eta_updated_at else now() end,
      updated_at=now() where id=p_order_id;
  elsif p_action='reject' and v_order.status='customer_submitted' then
    v_new_status := 'merchant_rejected';
    update public.orders set status=v_new_status,merchant_response_reason=trim(p_reason),updated_at=now()
      where id=p_order_id;
  elsif p_action='start_preparing' and v_order.status='merchant_accepted' then
    v_new_status := 'preparing';
    update public.orders set status=v_new_status,preparation_started_at=now(),updated_at=now()
      where id=p_order_id;
  elsif p_action='mark_ready' and v_order.status='preparing' then
    v_new_status := 'ready_for_pickup';
    update public.orders set status=v_new_status,preparation_completed_at=now(),updated_at=now()
      where id=p_order_id;
  else
    raise exception 'لا يمكن تنفيذ هذا الإجراء في حالة الطلب الحالية';
  end if;

  insert into public.order_events(order_id,actor_user_id,from_status,to_status,reason)
  values(p_order_id,v_user_id,v_order.status,v_new_status,nullif(trim(coalesce(p_reason,'')),''));
  return v_new_status;
end;
$function$;

create or replace function private.courier_update_order(p_order_id uuid,p_action text)
returns text
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_order public.orders%rowtype;
begin
  if v_user_id is null then raise exception 'يلزم تسجيل الدخول'; end if;
  if p_action <> 'en_route' then
    raise exception 'تجاوز مراحل الشراء أو التسليم غير مسموح؛ استخدم تأكيد الشراء أو تأكيد التسليم';
  end if;
  if not exists (
    select 1 from public.courier_assignments ca
    where ca.order_id=p_order_id and ca.courier_id=v_user_id and ca.status='accepted'
  ) then raise exception 'لا يوجد إسناد مقبول لهذا الطلب'; end if;

  select * into v_order from public.orders where id=p_order_id for update;
  if not found or v_order.status<>'picked_up' then
    raise exception 'سجّل تكلفة الشراء أولاً قبل بدء التوصيل';
  end if;
  if v_order.courier_purchase_total_mad is null then
    raise exception 'تكلفة شراء المنتجات مطلوبة قبل بدء التوصيل';
  end if;

  update public.orders set status='en_route',en_route_at=now(),updated_at=now()
    where id=p_order_id;
  insert into public.order_events(order_id,actor_user_id,from_status,to_status,reason)
  values(p_order_id,v_user_id,'picked_up','en_route','بدأ المندوب التوصيل بعد تسجيل تكلفة الشراء');
  return 'en_route';
end;
$function$;
