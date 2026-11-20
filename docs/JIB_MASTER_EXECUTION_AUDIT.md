# JIB — Master execution audit
**Audit date:** 2026-11-20  
**Scope:** Customer, Merchant, Courier, JIB Manager, Supabase, GitHub Actions, Android APKs, AI providers, notifications, image generation, branches, pricing, GPS, and release readiness.

This document separates verified implementation from unfinished work. A feature is not complete merely because a screen, migration, workflow, or configuration exists; it must pass automated checks and a real integration/device test.

## 1. Current repository and release state

- Repository: `hatimsawad/jib-delivery`.
- Working branch: `feature/jib-manager-standalone`.
- PR #4 remains Draft and unmerged. Do not merge or change the production alias without the owner's explicit approval.
- Latest audited source commit before this audit: `00f04c2fe1c3a7aff00f0c892c1fa3270a7cde1c`.
- On 2026-11-20, the merchant image-picker null-safety error was fixed and the Flutter CI matrix was changed to `fail-fast: false`.
- Latest GitHub CI run `44751553358`: admin lint/build, customer Flutter analyze/tests, courier Flutter analyze/tests, and merchant Flutter analyze/tests all passed.
- Latest Android APK run `44751552929`: all three apps passed analyze and tests; release APK build/upload jobs were still running at audit time. Do not call APK artifacts complete until the workflow succeeds and artifacts are available.
- Latest Vercel preview for commit `00f04c2...` is READY. It is a preview deployment, not production. Browser smoke testing is still required.
- No production alias was repointed, no PR was merged, and no paid plan or billing upgrade was activated.

## 2. Application implementation

### Customer app
- Verified source includes Supabase authentication, store/product discovery, cart, address capture, cash checkout, order history, and the order timeline display.
- The customer timeline reads the batched `jib_order_timeline` RPC and displays elapsed time, estimated remaining time, and estimated delivery time where available.
- Checkout still contains the temporary **15 MAD** delivery fee. This must be replaced by approved Rabat service-zone pricing before production.
- A full customer-to-merchant-to-courier device-to-device checkout and delivery test remains pending.

### Merchant app
- Verified source includes authentication, merchant/store onboarding, product create/edit/availability, genuine product-image upload, order list, and merchant status transitions.
- The order timeline display is present.
- Product AI image generation is intentionally disabled; merchants must upload genuine product/supplier images.
- Latest CI merchant analyze and widget tests passed after the null-safety correction.
- Merchant APK build was still running at audit time.

### Courier app
- Verified source includes authentication/enrollment, approval gate, available/assigned orders, atomic claim, pickup/delivery status changes, and order timeline display.
- GPS tracking has now been added to the courier source using Geolocator Android foreground-location service, explicit consent, persistent notification, secure RPC upload, 60-second cron disconnect checks, 90-day retention, and a JIB Manager tracking page. Real-device background/closed-app validation is still pending.
- Required but not yet implemented: explicit courier consent; Android foreground/background location permissions; persistent tracking notification; start/stop tied to the approved availability/login-to-logout policy; tracking behavior for active jobs; heartbeat/disconnect monitoring; and secure route retention.
- The approved operational requirements remain: tracking from login until logout with explicit informed consent and Android permissions; disconnect alert after 60 seconds; retain route history for 90 days. Do not silently weaken or reinterpret these rules.
- Latest CI courier analyze and widget tests passed. Courier APK build was still running at audit time.

### JIB Manager
- The independent Next.js admin dashboard has authenticated admin routes, live operational counts/read views, store/courier approval actions, brand directory, order views, monitoring, incident views, image review, and notification settings.
- CI admin lint and Next.js build passed.
- The order timeline backend/UI foundation exists; complete dispatch controls, pricing/service zones, financial settlement, full audit coverage, and end-to-end operations still require work.
- The current preview is READY; route-by-route authenticated smoke tests remain pending.

## 3. Supabase — live read-only audit

Read-only checks on 2026-11-20 confirmed:
- 17 of 17 public tables have RLS enabled.
- 46 migration versions are recorded as applied.
- 1 store, 1 product, and 1 order currently exist.
- The only store is onboarding-pending; there are **zero approved/open customer-orderable stores**. Do not activate it or invent a branch. Use a real, explicitly approved test branch for checkout E2E.
- Image jobs: 9 ready for review, 5 rejected, 4 failed.
- Notification outbox: 164 jobs awaiting provider.
- Health Advisor: no health lints.
- Performance Advisor: 23 unused-index informational notices. Do not drop indexes automatically on a low-traffic system; reassess after representative usage.

### Security Advisor findings
- 14 authenticated-callable SECURITY DEFINER functions are flagged. Read-only inspection confirmed anonymous EXECUTE is false for all 14. The inspected functions also contain authentication, role, ownership, or state-transition checks appropriate to their purpose. The warning is not proof of an exploit, but these functions still require adversarial tests for admin, customer, merchant, courier, and unauthenticated callers before release.
- Leaked-password protection is disabled. Enable it in Supabase Auth settings before public release.
- `pg_net` is installed in the public schema. It is used by the scheduled monitor; do not move or drop it without a tested migration plan.
- Do not revoke all authenticated EXECUTE grants indiscriminately: checkout, courier, merchant, admin, and image-job RPCs are application paths. Review each grant with negative/positive tests first.

## 4. Orders, branches, pricing, and loyalty

- Customer discovery and checkout enforce real branch approval, active/open state, and branch-policy gates.
- Current store remains onboarding-pending even though legacy active/open flags are true; onboarding approval is the decisive customer-visibility gate.
- Branch fulfillment/loyalty configuration is a foundation only. It does not mean external partner orders, API/POS ordering, cash advances, or external loyalty points are operational.
- Per-branch central ordering, digital ordering, API/POS, and loyalty modes remain approval-gated. Never fabricate chain branches or infer partnership from brand-directory approval.
- Cash is the only confirmed checkout method.
- Temporary 15 MAD delivery fee remains. Define and approve actual Rabat zones, delivery fees, merchant commission, and exception rules before changing the server-side price source.

## 5. JIB AI Manager, model team, and free-only provider plan

### AI Manager
- Monitoring and notification outbox foundations exist.
- Image generation route targets Cloudflare Workers AI FLUX.1 Schnell and article covers only. Product-image generation is disabled for authenticity.
- Vercel environment-variable entries named `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_API_TOKEN` exist for Preview and Production. Their values were not read. A successful real image generation → storage upload → human review test has not been verified. Confirm the Cloudflare account's billing plan before enabling any live generation.
- Notifications are not delivered. The dispatcher Edge Function is active but delivery remains disabled until owner activation and provider configuration. No email, SMS, WhatsApp, or voice delivery is claimed.
- The 164 outbox jobs remain awaiting a provider. Do not enable Twilio/voice or any usage-based service without explicit cost approval.

### GitHub multi-model development team
- Separate branch: `feature/jib-multi-model-ai-manager`.
- A manual GitHub Actions workflow and a four-role analysis script exist: architect, implementer, security, and QA.
- The workflow is read-only, free-model allowlist only, and produces a downloadable report; it cannot write code, create PRs, merge, deploy, or alter the database.
- It requires GitHub repository variables/secrets for the HTTPS provider endpoint, API key, and explicitly free model list. These are not verified as configured; no successful multi-model run is confirmed.
- The workflow exists only on its feature branch, not the default branch. It is not yet a dependable ready-to-run team until the workflow is included in an approved default-branch release and its free provider configuration is tested.
- The approved exploration list remains: OmniRoute as the primary routing candidate, LiteLLM as a fallback/router candidate, OpenRouter free models as a provider option, FreeLLMAPI-Extended for testing; Bifrost, New API, and One API remain alternatives rather than six simultaneous production gateways.
- The user-approved requirement is FreeLLMAPI for both developer assistance and JIB AI Manager, at zero cost. Integration must remain text-only initially, server-side, authenticated, redacted, rate-limited, with paid fallback disabled. It must not receive secrets/customer PII or perform SQL, image generation, deployment, billing, account-permission, or financial actions.
- None of these gateway services is claimed to be deployed or integrated into the live JIB runtime yet. Hosting availability, provider terms, free-model availability, privacy, and no-billing enforcement must be verified before activation.

## 6. Release gates still open

1. Complete all three release APK builds; download artifacts and install/test each on a real Android device.
2. Perform authenticated JIB Manager preview smoke tests and customer/merchant/courier end-to-end order tests with an explicitly approved real test branch.
3. Implement the approved courier GPS consent/permissions/background service, 60-second disconnect alert, and 90-day route retention; test on real Android devices and battery/background restrictions.
4. Complete adversarial authorization tests for all 14 flagged SECURITY DEFINER functions and every sensitive RPC.
5. Enable leaked-password protection in Supabase Auth.
6. Approve Rabat service zones and pricing; remove the temporary 15 MAD fee only after the replacement is approved and tested.
7. Configure and verify truly free push/email options where possible; keep paid SMS, WhatsApp, and voice disabled unless explicitly approved.
8. Complete the multi-model AI workflow provider configuration with a verified free-only model allowlist and a successful test artifact. Keep it read-only until a separately approved patch workflow exists.
9. Run the Cloudflare article-cover generation/storage/review test and verify the account billing plan before enabling it.
10. Complete partner ordering, API/POS, and loyalty integrations only after real partner authorization and technical credentials exist.
11. Review hosting terms for commercial use. A READY Vercel Hobby preview does not establish commercial production hosting permission.
12. Complete backup/restore, privacy, monitoring, and production release review.

## 7. Non-negotiable safety boundaries

- Keep PR #4 Draft until the owner explicitly approves review/merge.
- Do not repoint production, activate a real store, create fake branches, or alter live pricing without explicit approval.
- Do not enable paid services, paid model fallbacks, billing, subscriptions, paid messaging, or paid hosting without explicit approval.
- Never put provider secrets in source code, GitHub commits, mobile apps, logs, or prompts.
- Keep the multi-model development assistant separate from the JIB Manager runtime and enforce human approval for code changes.


## Addendum — execution after the initial audit (2026-11-20)
- Courier foreground GPS code and Android manifest permissions are now implemented on the feature branch. Supabase migration `20261120154500_add_consent_based_courier_location_tracking` has been applied, with cron checks every minute and daily 90-day retention cleanup.
- JIB Manager now includes `/tracking` and `/ai-manager`; the latter is an admin-only, advisory chat endpoint with a FreeLLMAPI OpenAI-compatible adapter. It remains disabled until secure HTTPS endpoint, key and free model are configured.
- The independent GitHub multi-model runner remains read-only and free-only. Its provider secrets/models are not configured or verified; a successful four-model run has not been demonstrated.
- The latest GPS/AI code changes triggered fresh CI and APK workflows. Treat these as pending until the newest run for the final commit is green.
- A READY APK from an earlier commit does not include the GPS implementation. Use only artifacts from the final successful run after GPS changes.
- Device testing, approved test branch/order E2E, live provider configuration, notification provider setup, service-zone pricing, and production release review remain required.


## Verified correction and execution update — 2026-11-20 (latest GitHub/Supabase checks)

This section supersedes stale status statements above where they conflict.

### GitHub failures reviewed
- Historical CI run `44765591064` on the superseded AI-team branch/PR #5 failed for two concrete reasons: ESLint 9 could not find an `eslint.config.*` file in that merge checkout, and Merchant Flutter had an undefined `generatedImage` reference at `apps/merchant/lib/main.dart:514`.
- PR #5 is closed, unmerged, and superseded. PR #6 is the clean standalone AI-team proposal based directly on `main`.
- The current JIB Manager branch's latest CI run `44766029532` passed all four jobs: admin, courier, merchant, and customer.
- A newer APK workflow run `44766029819` passed analyze/tests for all three apps; release APK build and upload were still in progress at the last poll. No APK download artifact was yet listed for that run.
- The earlier APK run `44765591105` had a Merchant failure due to the same obsolete `generatedImage` reference; do not use artifacts from that run.
- The AI-team runner validation run `44765747010` succeeded. Its multi-model analysis job was skipped because the event was a push, not a manual dispatch. This does not prove any model provider is connected.

### Courier tracking — database state verified
- The current courier app includes explicit consent, Geolocator Android foreground-location notification, authenticated location upload RPCs, a visible stop-sharing control, and stop-on-logout behavior.
- Supabase confirms migrations `20261120153458_add_consent_based_courier_location_tracking` and `20261120154227_auto_assign_nearest_consenting_courier` are applied.
- Supabase confirms three active cron jobs: stale-location check every minute; 90-day history pruning daily at 03:17 UTC; and unassigned-order dispatch retry every minute.
- The stale-location function flags a last location older than 60 seconds. Because it is cron-driven every minute, the incident may become visible up to one cron interval after the 60-second threshold.
- The courier APK workflow generates Android project files at build time. Its permission step has now been corrected so only the courier app receives coarse/fine location, foreground-service, location foreground-service, and notification permissions. Customer and merchant receive Internet permission only.
- The revised Android permission workflow and updated courier README were committed after run `44766029819`; therefore a fresh APK run is required before treating the permission-scoping change as validated.
- Real-device testing remains mandatory for background behavior, persistent notification, force-stop, battery restrictions, permission revocation, and network loss/recovery.

### Independent GitHub AI team
- PR #6 is open and Draft, with only four files: the workflow, runner script, setup guide, and architecture document. It is separate from JIB Manager PR #4.
- Latest validation succeeded, but the four-model execution remains untested. GitHub Actions values `JIB_AI_TEAM_BASE_URL`, `JIB_AI_TEAM_API_KEY`, and `JIB_AI_TEAM_FREE_MODELS_JSON` are not verified as configured. The API key must be added only as a GitHub Actions secret.
- The workflow is read-only and requires four distinct explicitly free model entries. Do not claim FreeLLMAPI or another provider is live until a successful manual run returns four responses and an artifact.

### Remaining launch blockers
- All three APK release artifacts from the final post-permission-change commit must finish and be checked; physical installation is still unverified.
- Authenticated JIB Manager preview smoke tests and a full customer → merchant → courier E2E order remain pending. The live database has no approved/open orderable store; do not activate the pending store without owner approval.
- Rabat delivery zones/pricing remain unapproved; checkout still uses the temporary 15 MAD fee.
- Notification delivery remains disabled pending a verified no-cost provider and owner-approved configuration.
- FreeLLMAPI/GitHub AI model credentials are not configured or tested.
- Supabase leaked-password protection and adversarial RPC authorization tests remain open.
- No merge, production deployment, billing activation, or paid provider activation is authorized by this audit.


## Latest hardening work — 2026-11-20

- Android APK workflow permissions were narrowed: only the courier build receives location and foreground-service permissions; customer and merchant receive only Internet permission. The courier app uses a visible, user-consented foreground service with an ongoing notification. Do not add `ACCESS_BACKGROUND_LOCATION` without a separate necessity review; the foreground service is started while the app is visible and continues while the app is backgrounded.
- JIB AI Manager server route now redacts common API keys, JWT-like tokens, emails, phone numbers, and precise coordinate pairs before forwarding prompts to FreeLLMAPI. It never sends the unsanitized prompt.
- Added migration `20261120160000_jib_ai_manager_chat_rate_limit.sql` for an atomic, private, per-admin limit of 20 messages per hour. The route fails closed (503) if this RPC is unavailable. **This migration is committed to the feature branch but has not been applied to the live Supabase project**, so the AI chat remains unavailable until the migration is explicitly approved and applied.
- The FreeLLMAPI endpoint, key, and free model are still not verified in Vercel. The route remains disabled until all three server-only values are configured. No provider key is available through the connected GitHub actions in this session.
- The GitHub AI-team workflow remains separate in PR #6. Its syntax-validation run passed; the four-model analysis was skipped on push and still needs the owner to configure the HTTPS endpoint, API key secret, and four explicitly free model entries.
- A new CI/APK run is required for the latest prompt-redaction, rate-limit, and courier-only Android permission changes. Treat them as pending until the run for the final PR #4 head is green.
