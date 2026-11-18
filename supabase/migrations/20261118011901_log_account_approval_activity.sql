-- Log security-relevant account and courier approval changes without copying contact details.
create or replace function public.jib_ai_manager_log_profile_role_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $function$
begin
  if old.role is distinct from new.role then
    insert into public.jib_ai_manager_events (
      fingerprint, event_type, severity, title, message, details, status
    ) values (
      'profile-role:' || new.id::text || ':' || gen_random_uuid()::text,
      'profile_role_change',
      'warning',
      'تغيير صلاحية حساب',
      'تم تغيير دور أحد الحسابات في JIB.',
      jsonb_build_object('profile_id', new.id, 'old_role', old.role, 'new_role', new.role),
      'acknowledged'
    );
  end if;
  return new;
end;
$function$;

create or replace function public.jib_ai_manager_log_courier_approval()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $function$
declare
  v_action text;
  v_severity text := 'info';
begin
  if tg_op = 'INSERT' then
    v_action := 'application_created';
  else
    if old.is_active is not distinct from new.is_active
       and old.approved_at is not distinct from new.approved_at then
      return new;
    end if;
    v_action := 'approval_updated';
    if old.is_active is distinct from new.is_active then
      v_severity := 'warning';
    end if;
  end if;

  insert into public.jib_ai_manager_events (
    fingerprint, event_type, severity, title, message, details, status
  ) values (
    'courier-approval:' || new.user_id::text || ':' || gen_random_uuid()::text,
    'courier_approval',
    v_severity,
    'تحديث اعتماد مندوب',
    case when v_action = 'application_created'
      then 'تم تسجيل طلب انضمام مندوب جديد.'
      else 'تم تحديث حالة اعتماد أو نشاط مندوب.'
    end,
    jsonb_build_object(
      'courier_user_id', new.user_id,
      'action', v_action,
      'is_active', new.is_active,
      'approved_at', new.approved_at
    ),
    'acknowledged'
  );
  return new;
end;
$function$;

revoke all on function public.jib_ai_manager_log_profile_role_change() from public, anon, authenticated;
revoke all on function public.jib_ai_manager_log_courier_approval() from public, anon, authenticated;

drop trigger if exists jib_ai_manager_profile_role_log on public.profiles;
create trigger jib_ai_manager_profile_role_log
  after update of role on public.profiles
  for each row execute function public.jib_ai_manager_log_profile_role_change();

drop trigger if exists jib_ai_manager_courier_approval_log on public.courier_profiles;
create trigger jib_ai_manager_courier_approval_log
  after insert or update on public.courier_profiles
  for each row execute function public.jib_ai_manager_log_courier_approval();
