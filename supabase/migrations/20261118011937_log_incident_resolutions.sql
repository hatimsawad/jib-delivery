-- Notify the owner when an open operational incident is resolved.
create or replace function public.jib_ai_manager_log_event_resolution()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $function$
begin
  if old.status = 'open' and new.status = 'resolved' then
    insert into public.jib_ai_manager_events (
      fingerprint, event_type, severity, title, message, details, status
    ) values (
      'resolution:' || old.id::text || ':' || gen_random_uuid()::text,
      'health_check_resolution',
      'info',
      'تم حل مشكلة تشغيلية',
      'تمت معالجة مشكلة سابقة في مراقبة JIB.',
      jsonb_build_object(
        'resolved_event_id', old.id,
        'resolved_fingerprint', old.fingerprint,
        'original_title', old.title,
        'resolved_at', coalesce(new.resolved_at, now())
      ),
      'acknowledged'
    );
  end if;
  return new;
end;
$function$;

revoke all on function public.jib_ai_manager_log_event_resolution() from public, anon, authenticated;

drop trigger if exists jib_ai_manager_event_resolution_log on public.jib_ai_manager_events;
create trigger jib_ai_manager_event_resolution_log
  after update of status on public.jib_ai_manager_events
  for each row execute function public.jib_ai_manager_log_event_resolution();
