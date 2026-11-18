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

## Existing backend capabilities

- Seven core application tables have RLS enabled: profiles, stores, products, addresses, orders, order_items and order_events.
- Supabase Auth and admin profile role exist.
- Checkout RPC validates signed-in customer, address ownership, active/open store, product availability and quantities; it reads prices from the database.
- Direct client writes to order tables are restricted.
- Merchant enrollment, courier enrollment, courier dashboard, courier claim/status RPCs, admin store approval and courier approval RPCs exist.
- An order event table records status changes that are currently implemented.

## Confirmed blockers and work still required

- Confirm admin sign-in and verify Supabase Auth redirect URLs in the deployed Manager environment.
- Review Supabase Security Advisor findings: authenticated-callable SECURITY DEFINER functions `checkout_order` and `is_jib_admin`, and leaked-password protection disabled. Test RPC authorization adversarially before public launch.
- Performance Advisor has RLS init-plan and multiple permissive-policy optimization warnings.
- Checkout currently uses a temporary 15 MAD delivery fee; replace it with approved Rabat service zones and server-validated pricing before production.
- Latest known application data was empty for stores, products and orders; seed real partner data only with their consent.
- Merchant and courier apps were still starters/placeholders in the last source review; live order handling and dispatch need completion and verification.
- Customer app integration was in progress and needed CI plus end-to-end verification.
- No signed production APK/AAB, production maps, verified push/SMS/WhatsApp/voice delivery, payment gateway, full courier dispatch, or live GPS tracking was confirmed.
- JIB Manager still needs detailed per-stage timeline/ETA, complete dispatch controls, pricing/service-zone management, financial settlement, admin audit log, notification-provider delivery status, incident automation and AI-provider integration.
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
