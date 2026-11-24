create or replace function private.merchant_set_branch_product(
  p_branch_id uuid,
  p_product_id uuid,
  p_price_mad numeric,
  p_available boolean
) returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid := auth.uid();
  v_id uuid;
  v_brand_id uuid;
begin
  if v_user is null then raise exception 'يلزم تسجيل الدخول'; end if;
  if p_price_mad is null or p_price_mad<0 then raise exception 'السعر غير صالح'; end if;
  if not exists(select 1 from public.products where id=p_product_id and is_active=true) then
    raise exception 'المنتج غير موجود في كتالوج JIB';
  end if;

  select m.brand_id into v_brand_id
  from public.branches b
  join public.merchants m on m.id=b.merchant_id
  where b.id=p_branch_id and m.owner_user_id=v_user
    and m.is_active=true and m.is_direct_purchase=true;
  if not found or v_brand_id is null then
    raise exception 'لا تملك صلاحية إدارة هذا الفرع أو أنه غير مرتبط بعلامة نشطة';
  end if;

  -- The JIB selling price is shared by every branch of the same brand.
  -- Availability remains branch-specific; only the price is synchronized.
  update public.branch_products bp
  set price_mad=p_price_mad,updated_at=now()
  from public.branches b
  join public.merchants m on m.id=b.merchant_id
  where bp.branch_id=b.id and bp.product_id=p_product_id
    and m.brand_id=v_brand_id;

  insert into public.branch_products(branch_id,product_id,price_mad,availability,is_active,confirmed_at)
  values(p_branch_id,p_product_id,p_price_mad,
    case when p_available then 'available' else 'unavailable' end,true,
    case when p_available then now() else null end)
  on conflict(branch_id,product_id) do update set
    price_mad=excluded.price_mad,
    availability=excluded.availability,
    is_active=true,
    confirmed_at=excluded.confirmed_at,
    updated_at=now()
  returning id into v_id;
  return v_id;
end;
$function$;
