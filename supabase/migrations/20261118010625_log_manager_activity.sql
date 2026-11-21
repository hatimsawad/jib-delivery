-- Record operational activity for JIB AI Manager without copying customer PII.
create or replace function public.jib_ai_manager_log_order_event()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
begin
  insert into public.jib_ai_manager_events (
    fingerprint, event_type, severity, title, message, details, status, first_seen_at, last_seen_at
  ) values (
    'order_event:' || new.id::text,
    'order_status',
    case when new.status in ('rejected', 'cancelled') then 'warning' else 'info' end,
    'تحديث حالة طلب',
    'تم تسجيل مرحلة جديدة في دورة الطلب.',
    jsonb_build_object('order_id', new.order_id, 'status', new.status),
    'acknowledged',
    new.created_at,
    new.created_at
  )
  on conflict (fingerprint) do nothing;
  return new;
end;
$function$;

create or replace function public.jib_ai_manager_log_catalog_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_id uuid;
  v_store_id uuid;
  v_action text := lower(tg_op);
begin
  if tg_op = 'DELETE' then
    v_id := old.id;
    v_store_id := old.store_id;
  else
    v_id := new.id;
    v_store_id := new.store_id;
  end if;

  insert into public.jib_ai_manager_events (
    fingerprint, event_type, severity, title, message, details, status
  ) values (
    'product:' || v_action || ':' || v_id::text || ':' || gen_random_uuid()::text,
    'product_change',
    'info',
    'تحديث في كتالوج المنتجات',
    case tg_op
      when 'INSERT' then 'تمت إضافة منتج إلى أحد المتاجر.'
      when 'UPDATE' then 'تم تحديث بيانات منتج أو توفره.'
      else 'تم حذف منتج من أحد المتاجر.'
    end,
    jsonb_build_object('product_id', v_id, 'store_id', v_store_id, 'action', v_action),
    'acknowledged'
  );
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$function$;

create or replace function public.jib_ai_manager_log_store_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_id uuid;
  v_action text := lower(tg_op);
begin
  if tg_op = 'DELETE' then
    v_id := old.id;
  else
    v_id := new.id;
  end if;

  insert into public.jib_ai_manager_events (
    fingerprint, event_type, severity, title, message, details, status
  ) values (
    'store:' || v_action || ':' || v_id::text || ':' || gen_random_uuid()::text,
    'store_change',
    'info',
    'تحديث في بيانات متجر',
    case tg_op
      when 'INSERT' then 'تم إنشاء متجر.'
      when 'UPDATE' then 'تم تحديث بيانات متجر أو حالة تشغيله.'
      else 'تم حذف متجر.'
    end,
    jsonb_build_object('store_id', v_id, 'action', v_action),
    'acknowledged'
  );
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$function$;

revoke all on function public.jib_ai_manager_log_order_event() from public, anon, authenticated;
revoke all on function public.jib_ai_manager_log_catalog_change() from public, anon, authenticated;
revoke all on function public.jib_ai_manager_log_store_change() from public, anon, authenticated;

drop trigger if exists jib_ai_manager_order_event_log on public.order_events;
create trigger jib_ai_manager_order_event_log
  after insert on public.order_events
  for each row execute function public.jib_ai_manager_log_order_event();

drop trigger if exists jib_ai_manager_product_log on public.products;
create trigger jib_ai_manager_product_log
  after insert or update or delete on public.products
  for each row execute function public.jib_ai_manager_log_catalog_change();

drop trigger if exists jib_ai_manager_store_log on public.stores;
create trigger jib_ai_manager_store_log
  after insert or update or delete on public.stores
  for each row execute function public.jib_ai_manager_log_store_change();
