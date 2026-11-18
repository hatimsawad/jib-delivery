-- The dispatcher is installed but stays inert until JIB_NOTIFICATIONS_ENABLED=true
-- and at least one provider's server-side secrets are configured.
do $$
declare
  v_job_id bigint;
begin
  for v_job_id in
    select jobid from cron.job where jobname = 'jib-ai-manager-notification-dispatch'
  loop
    perform cron.unschedule(v_job_id);
  end loop;
end
$$;

select cron.schedule(
  'jib-ai-manager-notification-dispatch',
  '* * * * *',
  $job$
    select net.http_post(
      url := (select decrypted_secret from vault.decrypted_secrets where name='jib_project_url') || '/functions/v1/jib-ai-manager-dispatch',
      headers := jsonb_build_object(
        'Content-Type','application/json',
        'apikey',(select decrypted_secret from vault.decrypted_secrets where name='jib_publishable_key'),
        'x-jib-dispatch-secret',(select decrypted_secret from vault.decrypted_secrets where name='jib_ai_manager_dispatch_secret')
      ),
      body := jsonb_build_object('source','pg_cron'),
      timeout_milliseconds := 20000
    );
  $job$
);
