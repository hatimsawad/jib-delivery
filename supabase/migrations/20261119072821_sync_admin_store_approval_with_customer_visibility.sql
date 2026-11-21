-- Keep the admin approval action consistent with customer discovery and checkout.
CREATE OR REPLACE FUNCTION public.admin_set_store_status(p_store_id uuid, p_is_active boolean, p_is_open boolean DEFAULT false)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
begin
  if (select auth.uid()) is null or not public.is_jib_admin() then
    raise exception 'صلاحية الإدارة مطلوبة';
  end if;

  update public.stores
  set is_active = p_is_active,
      is_open = (p_is_active and p_is_open),
      onboarding_status = case when p_is_active then 'approved' else onboarding_status end,
      updated_at = now()
  where id = p_store_id;

  if not found then
    raise exception 'المتجر غير موجود';
  end if;
end;
$function$;
