# JIB implementation status

Last updated: 2026-11-18

## Confirmed project structure and deployment history

- GitHub monorepo: `hatimsawad/jib-delivery`.
- Flutter apps: customer, merchant and courier.
- Standalone Next.js administration web app: `apps/admin`, now branded **JIB Manager**. The directory is intentionally retained to preserve the existing Vercel project root and deployment configuration. JIB Manager is deployed separately from the three mobile apps and uses Supabase SSR authentication with server-side admin-role checks.
- Existing JIB Manager pages: dashboard, orders, stores, products, users, login and password recovery.
- Existing Supabase project: JIB, ref `emvleaghjsmzjmzgguvu`, region `eu-west-3`.
- Existing GitHub Actions workflow builds the manager app and analyzes/tests all three Flutter apps.
- Existing Vercel project `jib-admin` had a previously verified READY deployment. Changes on the current feature branch still require CI and preview-deployment verification.

## Work added in this development pass

- Created branch `feature/jib-manager-standalone` from `main`.
- Added the independent JIB Manager product/technical specification at `docs/JIB_MANAGER_SPEC.md`.
- Rebranded the web console as JIB Manager without changing its deployment directory.
- Expanded the dashboard with live database counts for total orders, pending orders, preparation, active deliveries, active stores, products and active couriers.
- Added explicit read-error status so failed database reads are not presented as healthy metrics.
- Updated Manager setup and safety documentation.
- These changes are committed on the feature branch; they are not yet merged into main or verified by CI.

## Work added during the current continuation

- Added a private health-check history table and an incident table with admin-only read access and service-role write access.
- Deployed the Supabase Edge Function `jib-ai-manager-monitor`. It checks the JIB Manager login endpoint, database read health, notification preference completeness and the `product-images` storage bucket; it stores metrics without customer PII and records/resolves operational incidents.
- Enabled `pg_cron` and `pg_net`, stored the monitor endpoint, publishable API key and a private monitor token in Supabase Vault, and scheduled the health check every five minutes.
- Verified a manual scheduled-function invocation end to end: the JIB Manager endpoint returned HTTP 200, Supabase reads and the product image bucket check succeeded, and the latest recorded health status was `healthy` (one order, one active store, one product and one active courier at that check).
- Added the admin-only monitoring page at `/monitoring` and navigation entry, with a readable incident/activity feed.
- Added database triggers that record order status events, store/product create/update/delete activity, profile-role changes and courier application/approval changes without copying customer contact details. Trigger behavior was tested in rolled-back transactions.
- Added a RLS-respecting batched order timeline RPC. Courier assignment is now a distinct timestamp (the duplicate historical ready-for-pickup event was corrected). Customer, merchant and courier app screens now request and display elapsed/remaining time and stage timestamps; final Flutter CI verification is pending. ETA uses a labeled baseline until at least five completed visible orders are available, then uses historical medians.
- Optimized RLS auth checks and consolidated additive SELECT policies. Supabase Performance Advisor no longer reports auth-initplan or multiple-permissive-policy warnings; only unused-index informational suggestions remain.
- Verified the scheduled cron execution succeeded and created a second healthy check at HTTP 200.
- Added a private idempotent notification outbox. Every new operational incident/activity and every resolved incident is queued for the four selected channels and remains `awaiting_provider`; rolled-back tests confirmed four jobs per event and resolution. No sender runs and no paid messages/calls are sent until accounts, credentials and owner approval exist.
- The monitor does not yet deliver email, SMS, WhatsApp or voice notifications. Provider credentials are not configured.

## Existing backend capabilities

- Seven core application tables have RLS enabled: profiles, stores, products, addresses, orders, order_items and order_events.
- Supabase Auth and admin profile role exist.
- Checkout RPC validates signed-in customer, address ownership, active/open store, product availability and quantities; it reads prices from the database.
- Direct client writes to order tables are restricted.
- Merchant enrollment, courier enrollment, courier dashboard, courier claim/status RPCs, admin store approval and courier approval RPCs exist.
- An order event table records status changes that are currently implemented.

## Confirmed blockers and work still required

- Confirm admin sign-in and verify Supabase Auth redirect URLs in the deployed Manager environment.
- Security Advisor still reports ten authenticated-callable SECURITY DEFINER RPCs. Their definitions and grants were inspected: anonymous execution is denied and the functions perform role/ownership checks; retain them pending adversarial authorization tests. Leaked-password protection remains disabled and must be enabled in Supabase Auth settings.
- Security Advisor also flags pg_net's extension metadata in the public schema. pg_net is non-relocatable in this project; do not drop it casually because the scheduled monitor depends on it.
- Checkout currently uses a temporary 15 MAD delivery fee; replace it with approved Rabat service zones and server-validated pricing before production.
- At the latest health check, the database contained one order, one active store and one product; there were zero active couriers. These are live counts, not a claim that the marketplace is ready for launch.
- Source review of the current main branch confirms customer app baseline: Supabase sign-in/registration, store/product browsing, local cart, address capture, checkout RPC and order history. CI and a complete device-to-device order test remain required.
- Source review confirms merchant baseline: Supabase auth, merchant/store enrollment, product create/edit/availability, product image upload to Supabase Storage, incoming orders and merchant status transitions. CI, image-policy verification and end-to-end testing remain required.
- Source review confirms courier baseline: Supabase auth/enrollment, admin-approval gate, available/assigned delivery list, atomic claim RPC and picked-up/delivering/delivered status updates. CI, location/privacy checks and end-to-end testing remain required.
- No signed production APK/AAB, production maps, verified push/SMS/WhatsApp/voice delivery, payment gateway, full courier dispatch, or live GPS tracking was confirmed.
- JIB still needs complete dispatch controls, pricing/service-zone management, financial settlement, notification-provider delivery status and AI diagnosis/repair workflow. The JIB Manager image-generation route and human approval UI now target Cloudflare Workers AI FLUX.1 Schnell, but live generation remains blocked until the account ID and API token are added to Vercel and a real generation/storage/review test passes. The agreed Arabic/French/English simultaneous content display across all major screens remains to be implemented and verified.
- Stored notification preferences do not prove provider connectivity. Provider accounts, credentials, templates, opt-in/consent and delivery tests are required.

## Required next engineering sequence

1. Run CI and Vercel preview checks for the JIB Manager feature branch; fix build, lint and type errors.
2. Complete order transition/dispatch RPCs and comprehensive event timestamps with role-based authorization.
3. Add customer-visible elapsed time and honest ETA based on operational data.
4. Connect merchant app to Supabase Auth, store/product management and incoming orders.
5. Connect courier app to Supabase Auth, approval, availability, atomic claim and delivery status.
6. Agree Rabat service areas, delivery pricing and platform commission; remove temporary pricing.
7. Add notification delivery adapters and test email, SMS, WhatsApp and voice independently.
8. Add maps only after selecting a provider and configuring restricted keys.
9. Complete security tests, full order journey tests and Android build/signing.
10. Run a controlled Rabat pilot with consenting merchants and couriers before public launch.

A feature is complete only after code, CI, security checks and a real integration test support that claim. This is not yet a production-ready delivery service.


## Notification dispatch status (2026-11-18)

- Supabase Edge Function `jib-ai-manager-dispatch` is deployed and scheduled every minute.
- It uses a separate Vault-held dispatch secret, service-role-only claim RPC, row locking, retry backoff, stale-lock recovery, and per-channel provider detection.
- It remains intentionally inert until `JIB_NOTIFICATIONS_ENABLED=true` and provider secrets are configured. No email, SMS, WhatsApp message, or voice call has been sent.
- Voice is additionally blocked until `JIB_VOICE_MONTHLY_BUDGET_USD` is set. The dispatcher reserves USD 1.50 per Moroccan mobile call as a conservative allowance; actual call/TTS charges can vary.
- WhatsApp requires a configured approved Content Template SID; Morocco SMS sender registration is a separate prerequisite.


## Cloudflare image-generation migration (2026-11-18)

- Replaced the Vercel AI Gateway call in `apps/admin/app/api/ai/generate-image/route.ts` with the Cloudflare Workers AI REST API and `@cf/black-forest-labs/flux-1-schnell` (4 steps).
- Provider configuration is checked before an image job is reserved. Missing/invalid credentials return a clear setup response without consuming the monthly JIB image quota.
- Generated JPEG bytes are size-checked, uploaded to the existing Supabase image bucket under a job-specific path, and finalized only after the existing authenticated owner/admin, Storage-object ownership, exact-path and URL checks pass.
- The finalization RPC now accepts only the Cloudflare model ID and a bounded estimated cost; anonymous execution remains revoked. Images remain `ready_for_review` until explicit human approval.
- JIB monthly reservation cap remains 100 image jobs. Cloudflare's daily free allocation is shared at account level and is not a guaranteed image count; requests can be rate-limited or stop when the available quota is exhausted.
- Required server-only Vercel variables: `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_API_TOKEN`. Token needs Workers AI Read and Write permissions. Never use a `NEXT_PUBLIC_` prefix.
- The Cloudflare migration is committed on the feature branch and applied to Supabase. A database read-back confirmed the finalization function uses the Cloudflare model allow-list and retains `anon_exec=false`, `authenticated_exec=true`.
- No live image request has been run because the Cloudflare account credentials are not yet configured. Do not mark image generation production-ready until the owner adds the secrets, a new deployment is READY, and a real image completes upload and approval.
- Latest CI workflows were queued at the time of the check. Vercel reported a build-rate-limit failure for the newer branch commits; the last known READY preview predates the final route/UI/docs changes. Recheck CI and preview after the deployment rate limit clears.
