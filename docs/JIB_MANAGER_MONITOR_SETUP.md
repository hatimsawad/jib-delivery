# JIB AI Manager monitor setup

The production Supabase project already has the monitor function deployed, its Vault values stored, and a five-minute cron job enabled. This document keeps the setup reproducible for another environment.

## Required Vault values

Create these secrets in Supabase Vault (never commit actual values):
- `jib_project_url`: `https://<project-ref>.supabase.co`
- `jib_publishable_key`: the project's publishable API key
- `jib_ai_manager_monitor_secret`: a random, private token (at least 32 random bytes)

The Edge Function also uses the Supabase server-side secret key supplied by the Edge Functions runtime. Do not place it in Git or client apps.

## Deploy

Deploy `supabase/functions/jib-ai-manager-monitor/index.ts` with `verify_jwt = false`. The function validates both the publishable `apikey` and a separate Vault-backed `x-jib-monitor-secret` header before using the server-side key.

## Schedule every five minutes

After creating the Vault values and deploying the function, run this SQL once:

```sql
select cron.schedule(
  'jib-ai-manager-health-check',
  '*/5 * * * *',
  $job$
    select net.http_post(
      url := (
        select decrypted_secret from vault.decrypted_secrets
        where name = 'jib_project_url'
      ) || '/functions/v1/jib-ai-manager-monitor',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'apikey', (
          select decrypted_secret from vault.decrypted_secrets
          where name = 'jib_publishable_key'
        ),
        'x-jib-monitor-secret', (
          select decrypted_secret from vault.decrypted_secrets
          where name = 'jib_ai_manager_monitor_secret'
        )
      ),
      body := jsonb_build_object('source', 'pg_cron')
    );
  $job$
);
```

The health monitor checks the JIB Manager login endpoint and basic database reads. It does not send email, SMS, WhatsApp or voice calls. Those require separate provider credentials, consent/template setup and delivery tests.
