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
- **GPS tracking is not implemented in the current courier source.** The reviewed app file contains no location plugin, location permission flow, background location service, or position upload flow.
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
