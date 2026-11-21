# JIB implementation status

Last updated: 2026-11-19

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


## Deep review update — 2026-11-19

- The live Supabase organization and project are confirmed on the Free plan; the project is `ACTIVE_HEALTHY` on PostgreSQL 17.11 in `eu-west-3`.
- Current schema inspection found 13 public application tables and all 13 have RLS enabled. Operational incident records are stored in `jib_ai_manager_events`; there is no separate `jib_ai_manager_incidents` table. Health history is stored in `jib_ai_manager_health_checks`.
- Supabase cron jobs are active: health check every five minutes and notification dispatcher every minute. The last three recorded monitor checks were `healthy`, HTTP 200, with empty issue lists. The live monitor metrics show one order, one active store, one product, one active courier, and a reachable product-image bucket at the latest check.
- The notification outbox currently contains 44 jobs in `awaiting_provider`. This is intentional: sender credentials are not configured and no notification provider has been activated. No email, SMS, WhatsApp message or voice call has been sent.
- Image generation was proven end-to-end for an article image: a real job reached `ready_for_review` and was later rejected during human review. The storage-owner UUID/text mismatch has been fixed in the live database and committed to this branch. The earlier Vercel AI Gateway path is retired because it required payment-card verification.
- FLUX.1 Schnell generation was improved on the feature branch: prompt design was refined for product fidelity and premium food photography, and inference steps increased from 4 to the model maximum of 8. The app's 100-job monthly cap is a separate abuse-control limit, not a promise of 100 free generations. Cloudflare Workers Free has a shared 10,000-Neuron daily allocation; further calls fail after the daily allocation is exhausted. Do not move the Cloudflare account to Workers Paid or enable paid AI billing without explicit approval.
- A live SQL migration added covering indexes for the three previously unindexed foreign keys on `jib_ai_manager_image_jobs`; all three indexes were verified in `pg_indexes`. Performance Advisor no longer reports missing foreign-key indexes; unused-index notices are informational for this low-traffic database.
- The current CI run on the branch includes successful admin build and Flutter static/widget checks; APK build status should be refreshed from the latest workflow run before publishing APKs. Earlier successful branch artifacts exist for all three applications, but they predate the newest non-mobile changes.
- The Vercel preview for the current code and index migration is `READY`. Production alias still points to the `main` branch and was not changed by this review.
- The Vercel Hobby plan is restricted to personal/non-commercial usage by Vercel's terms. It must not be treated as an eligible long-term hosting plan for a commercial delivery business. A Cloudflare Workers migration is the preferred no-cost technical path to evaluate, but it must pass Next.js compatibility, auth, image upload, monitoring, and complete order-flow tests before any production cutover.
- Remaining production blockers: enable leaked-password protection in Supabase Auth settings; conduct adversarial authorization tests for authenticated-callable `SECURITY DEFINER` RPCs before deciding on grants; define Rabat service zones and replace the temporary 15 MAD fee; configure truly free app-push delivery and test it; complete maps/live GPS and full cross-device order journey tests; validate signing/distribution of final Android builds; and move JIB Manager off Vercel Hobby before commercial use.



## Branch-specific fulfillment and loyalty foundation (2026-11-19)

- Added an admin-only `store_branch_policies` table. Each branch can independently select courier-led ordering, JIB central ordering, the store's official digital channel, or an authorized API/POS integration.
- Central ordering, official digital ordering and API/POS modes are blocked unless branch-specific approval is recorded. Digital ordering requires an HTTPS URL; API/POS checkout is blocked unless a connected partner integration exists.
- Added branch-specific loyalty modes: no external program, JIB business account, partner business account, or JIB Rewards. External loyalty account modes require explicit approval and a program name.
- Updated trusted `checkout_order` to read these settings on the server and snapshot fulfillment mode and loyalty mode/name onto each order. Order history in JIB Manager now displays those snapshots.
- Approval cannot be marked approved without a recorded reference and admin/timestamp audit fields. Pending/rejected/suspended requests can be stored without enabling the restricted branch mode.
- Added a per-branch editor to JIB Manager's Stores page. RLS and explicit authenticated table grants restrict policy records to JIB administrators; no anonymous access or secret credential storage was added.
- Added no paid service, external provider, subscription or billing upgrade.
- This is the configuration and checkout-snapshot foundation only. It does **not** yet automate JIB staff ordering, implement a complete courier purchase/advance-cash flow, connect store websites/APIs, or issue/redeem external/JIB loyalty points. Do not represent those operational steps as live until their queue, mobile screens, ledger and end-to-end tests are implemented.
- The migration is committed to PR #4's feature branch only and has not been applied to the live Supabase database. Run migration validation, admin lint/build, security review and an end-to-end checkout test on a safe database before merge or production release.
This review does not mark JIB production-ready. Keep PR #4 as Draft and do not merge or repoint production until the remaining blockers and migration tests are complete.

- Storage authorization was re-reviewed. Article uploads are admin-only; product uploads are limited to an authenticated merchant's own store (and admins for authorized support), while public access is read-only through the public buckets. Authenticated deletes are restricted to the owning store or admin. This makes the image-route cleanup attempt work for newly failed uploads without granting public write/delete access. Two historical article-image objects associated with pre-fix failed jobs remain orphaned in Storage; they were identified but not deleted by direct SQL because Storage objects must be removed through the Storage API.


## Moroccan culinary image knowledge update

- Added a curated multilingual dish-profile library for Moroccan/French tacos, tajine, couscous, pastilla, harira, rfissa, tanjia, msemen, chebakia, zaalouk, bissara, briouats, maakouda and seffa.
- Updated image prompting to match both product title and description and place the regional dish definition before generic photography instructions, preventing dish constraints from being truncated behind generic prompt text.
- Product prompts explicitly prioritize the prepared food itself and reject people, cooks, kitchens, rooms and unrelated lifestyle scenes. Dish-specific exclusions distinguish Moroccan/French tacos from Mexican tacos and Moroccan tajine from generic pots or cooking scenes.
- Corrected the Image Studio model-step description to eight steps to match the API.
- Documented free-source licensing and attribution rules in `docs/MOROCCAN_FOOD_KNOWLEDGE.md`. No paid provider or dataset was added.
- These changes require fresh CI and a new preview image test; they are not yet approved for production.


## Universal commercial catalog and chain-store scope (2026-11-19)

- Added `apps/admin/lib/ai/commercial-catalog.ts`: multilingual category detection and category-specific e-commerce image direction for prepared food, bakery, beverages, grocery, fresh produce, meat/seafood, household, personal care, electronics, fashion, beauty, flowers/gifts, toys, books/stationery, pet supplies, sports/outdoors, automotive and pharmacy/general merchandise.
- Image generation now uses the universal commercial catalog prompt for every product request, while retaining the Moroccan dish visual profiles as a specialized food reference. It requires the actual sellable item, avoids unrelated people/interiors, and prohibits invented logos, packaging text, claims and features.
- Fixed whitespace normalization in the image API prompt builder.
- Added an additive migration for store brand/chain metadata, product category/brand/SKU/barcode/attributes/external IDs, and a store integration registry. Integration credentials are expressly excluded from this table; admin-only integration management is enforced by RLS.
- Updated product specification for chain-level accounts, branches, menu/catalog onboarding, manual import, official partner API and POS pathways.
- McDonald's, Burger King, KFC and other chains are supported as target partner types in the architecture, but no commercial partnership or live API connection is claimed. These require each brand's authorization, data access and technical credentials.
- The new migration is committed to the feature branch but has not yet been applied to the live Supabase database. CI/build and preview deployment are required before release.
- Free-only policy remains in force. No paid provider, subscription, scraping service or billing upgrade was added.


## Global commercial brand catalog (2026-11-19)

- Added an initial directory seed of 50 Moroccan and international brand records across food, supermarkets, grocery, beverages, electronics, fashion, beauty, household, sports and toys. This is a starter dataset, not a claim to enumerate every merchant worldwide.
- Added the JIB Manager `/brands` page to add brands with source metadata and review/approve/reject/suspend their directory status.
- Added a navigation entry for the global brand directory.
- Brand-directory approval is deliberately separate from a real branch's merchant onboarding, operating hours, product availability and permission to accept JIB orders. A directory brand does not create a fake store branch or imply a partnership.
- Customer discovery continues to show only real store records that are active and open. Branch approval and onboarding remain the switch that makes a store available to customers.
- Seed migration `20261119140000_seed_global_commercial_brands.sql` and the new admin UI are committed to the feature branch only. The migration has not been applied to the live Supabase project.
- Vercel preview for commit `7fa52aad5d11280faeabddb5aab01c0445e28d5c` reached READY. GitHub CI and Android APK workflows were still queued at the last status check; they must pass before the feature is considered verified.


## Authoritative release audit — 2026-11-19 (supersedes earlier pending-migration notes)

- Live Supabase migration history confirms that the commercial catalog, 50-brand seed (plus one previously present/added record), branch fulfillment/loyalty configuration, policy optimization, and image-review hardening migrations are applied. Current read-only count: 51 brand rows, 47 pending verification, 4 approved directory entries; 1 store branch and 1 product row. Directory approval is not branch approval.
- The only current store row is `blackness`, with `onboarding_status='pending'`. It is intentionally not visible/orderable to customers until a JIB admin approves the actual branch. Do not auto-approve it or create fictitious chain branches.
- Added database-side customer checkout enforcement requiring the branch to be active, open, and `onboarding_status='approved'`. Customer discovery applies the same onboarding filter. The admin store-approval RPC now changes onboarding status to approved when an administrator activates a branch; the Stores page displays the actual onboarding state and its action can approve a pending branch even if the legacy `is_active` flag was already true.
- Hardened `jib_ai_manager_review_image_job`: null/missing profile roles no longer bypass product-image review authorization; only supported request types are accepted; anonymous execution is revoked. AI-generated product images are no longer eligible for publication as authentic product photos. Article-cover review remains admin-only.
- Disabled the text-to-image product endpoint and removed the product AI-generation control from the merchant app. Product catalog images must be uploaded from a real merchant/supplier/product source. Customer UI already labels historical AI-generated product images, but the new release does not create or approve additional AI product photos.
- Live image-job audit: 18 jobs total, 9 currently ready for review and 4 failed at the audit snapshot; the latest jobs were article-cover requests using Cloudflare FLUX.1 Schnell. No claim is made that image quality meets commercial standards; reject unsuitable article covers.
- Latest pre-fix CI and Android workflow runs succeeded for commit `6ebc11bd4caba40724a169ab9a27a66e5c06c40c`. New CI run `44479692586` and Android APK run `44479692672` were queued/in progress after the latest image-policy changes; recheck before calling the candidate verified.
- Latest Vercel preview deployment for commit `0b8f85030af4ef1f5cb9286a445b0c6d98dd3813` was queued at the last check. Do not use the previous READY preview as evidence for the newest source changes. Wait for the latest deployment to reach READY and smoke-test the protected admin routes.
- Supabase Security Advisor still reports: `pg_net` installed in public; 14 authenticated-callable SECURITY DEFINER functions; and leaked-password protection disabled. Anonymous execution is denied for the reviewed functions; the business RPCs contain auth/role/ownership checks. The image review function was hardened in this pass. Do not remove the scheduled monitor's pg_net dependency without a migration plan. Enable leaked-password protection in Supabase Auth dashboard before public release.
- The image-generation API now allows article covers only. Cloudflare usage still follows the account's actual billing plan and shared daily allocation. JIB does not upgrade plans or turn on billing; do not assume the API can guarantee a zero-cost call if the Cloudflare account itself is on a paid plan.
- PR #4 remains Draft and unmerged. Production alias remains unchanged. No final public launch, payment integration, automated branch ordering, courier cash advance, external loyalty accrual, live GPS tracking, or notification delivery is claimed.
- Next release gates: latest CI + APK workflow pass; latest Vercel preview READY and smoke-tested; branch approval UX test; customer browse/checkout E2E with an approved test branch; unauthorized RPC tests; final Android install/device test; verify Cloudflare account billing plan before enabling article image generation; configure free push notifications or clearly keep notifications disabled; service zones and real delivery pricing; production hosting terms review.


## تحديث تنفيذ 2026-11-20 — GPS وAI Manager
- أضيفت تبعيات `geolocator` و`shared_preferences` إلى تطبيق المندوب.
- يطلب التطبيق موافقة صريحة قبل مشاركة الموقع، ويعرض سبب التتبع وفترة الاحتفاظ 90 يوماً وإشعار Android الدائم، ويوفر إيقاف المشاركة.
- يستخدم Android foreground location notification مع تحديث كل 30 ثانية أو بعد انتقال 25 متراً؛ يتم إرسال الإحداثيات إلى RPC محمي لا يقبل إلا المندوب المعتمد الذي فعّل الموافقة.
- أضيفت صلاحيات ACCESS_FINE_LOCATION وACCESS_COARSE_LOCATION وACCESS_BACKGROUND_LOCATION وFOREGROUND_SERVICE وFOREGROUND_SERVICE_LOCATION وPOST_NOTIFICATIONS إلى مشروع Android المولد في workflow.
- أضيفت جداول `courier_location_tracking` و`courier_location_events` بسياسات RLS، وفحص انقطاع بعد 60 ثانية كل دقيقة، وتنظيف مجدول لنقاط الموقع الأقدم من 90 يوماً.
- أضيفت صفحة JIB Manager `/tracking` لعرض جلسات المشاركة وآخر نقطة وحالة الانقطاع، وأضيف نوع الحدث إلى شاشة المراقبة.
- تم تطبيق migration `20261120153458_add_consent_based_courier_location_tracking.sql` على مشروع Supabase المرتبط. جرى التحقق من وجود مهمتي cron للفحص والتنظيف. لا توجد نقاط GPS حالياً لأن لا مندوباً فعلياً وافق وبدأ الإرسال.
- أضيفت واجهة `/ai-manager` وAPI محمي للمدير فقط يرسل إلى FreeLLMAPI عبر HTTPS، ويوقف الطلب عند نفاد الحصة أو فشل المزود، دون paid fallback أو أدوات تنفيذ أو SQL.
- FreeLLMAPI غير مربوط بعد: متغيرات Vercel السرية `FREELLMAPI_BASE_URL`, `FREELLMAPI_API_KEY`, `FREELLMAPI_FREE_MODEL` لم يتم التحقق من وجودها/قيمها. لا تضع المفتاح في Git.
- فريق GitHub متعدد النماذج مستقل على `feature/jib-multi-model-ai-manager`. فحص syntax للـrunner نجح، لكن تشغيل النماذج يتطلب endpoint HTTPS ومفتاح GitHub Actions وأربعة model IDs موثقة كمجانية. لا يوجد paid fallback.
- يلزم نجاح CI وAPK على هذه التغييرات، ثم اختبار ميداني حقيقي لخدمة الموقع في الخلفية. لا نعد GPS مكتملاً ميدانياً قبل الاختبار على أجهزة Android.
