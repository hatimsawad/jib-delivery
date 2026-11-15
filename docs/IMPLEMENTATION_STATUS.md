# JIB implementation status

Last updated: 2026-11-15

## Confirmed in GitHub and Vercel

- Product specification, architecture, roadmap and setup documentation.
- Flutter starter projects for customer, courier and merchant roles.
- Next.js Arabic RTL admin app with Supabase SSR authentication, password recovery, callback and password-update routes.
- Admin dashboard with live Supabase-backed overview counts and read-only pages for orders, stores, products and users.
- Latest verified production deployment: Vercel project `jib-admin`, deployment state `READY`; deployed commit includes the four admin list pages and row-type fixes.
- Admin route build output confirmed: `/`, `/login`, `/login/forgot-password`, `/auth/callback`, `/update-password`, `/orders`, `/stores`, `/products`, `/users`.
- GitHub Actions CI workflow. A previously verified run passed the admin build and all three Flutter analyze/widget-test jobs.
- Six original Supabase migrations plus the client-grants hardening migration. The current Supabase migration history contains eight entries; the `tighten_client_table_grants` name appears twice under separate versions (idempotent SQL).
- Customer Flutter app work has started: Supabase initialization, email/password sign-in and registration, live store/product reads, local cart, address capture, cash checkout RPC and customer order history have been committed. CI validation is pending for the latest changes.

## Live Supabase project

- Project: JIB; ref: `emvleaghjsmzjmzgguvu`; region: `eu-west-3` (Paris).
- Seven public application tables have Row Level Security enabled: profiles, stores, products, addresses, orders, order_items and order_events.
- A confirmed Supabase Auth user with the `admin` profile role exists.
- Supabase URL and publishable key are configured in Vercel for production, preview and development. The mobile customer app uses the public publishable key; no service-role key is embedded in the client.
- Checkout RPC validates the signed-in customer, address ownership, active/open store, product availability and quantities; it reads prices from the database and creates order and item records transactionally.
- Direct client writes to orders/order_items/order_events are not allowed.
- Client table grants were hardened: authenticated users can read RLS-filtered rows; merchants can write stores/products only through owner-scoped RLS; customers can manage their own addresses; users can update only profile name, phone and language.
- Verified database privileges: authenticated cannot update profile role, cannot insert orders directly, and anonymous users cannot read stores. Authenticated profile-name edits, store/product inserts and address inserts are permitted subject to RLS.
- Trigger-only SECURITY DEFINER functions have direct API execution revoked.
- The user reports successfully completing the password reset and setting a new password on 2026-11-15. This confirms the reset flow reached the password-update step; a separate admin sign-in check is still pending.

## Confirmed blockers and security review

- The user successfully completed a password reset after the SMTP settings were updated. Confirm the admin can sign in with the new password and check that the recovery redirect allow-list is correct.
- A Google App Password-like value was previously exposed in chat. Revoke it in Google Account security settings and create a replacement. Never commit SMTP credentials to Git or paste them into chat.
- Supabase Security Advisor still reports two authenticated-callable SECURITY DEFINER functions: `checkout_order` (intended authenticated checkout endpoint) and `is_jib_admin` (used by admin RLS policies). Review and adversarially test these before public launch.
- Supabase Security Advisor reports leaked-password protection disabled.
- Performance Advisor reports RLS init-plan and multiple permissive-policy optimization opportunities. These are performance warnings, not by themselves evidence of a data leak.
- The checkout function currently uses a temporary 15 MAD delivery fee. This must be replaced with a validated pricing and service-area model.
- Current application data is empty for stores, products and orders. A public customer launch would therefore have no merchant inventory to serve.
- Merchant and courier Flutter apps remain visual starters with placeholder content; live authentication, merchant order management, courier dispatch and tracking are not complete.
- Customer app integration is in progress and must pass CI and end-to-end testing before it is treated as complete.
- No signed production APK/AAB, payment gateway, production maps, push notifications, courier dispatch or live tracking is complete.

## Next engineering tasks

1. Confirm admin sign-in and verify Supabase Auth redirect URLs.
2. Finish and verify the customer Flutter app integration, including signup, browsing, cart, checkout and order history.
3. Connect the merchant app to Supabase Auth, store/product management and incoming orders.
4. Connect the courier app to Supabase Auth, availability, assigned tasks and delivery status.
5. Add safe, database-authorized merchant order acceptance/state transitions and courier assignment/availability operations with audit events.
6. Decide the delivery fee and Rabat service zones; remove the temporary 15 MAD fee from checkout.
7. Add maps, notifications, payment integration after provider approval, automated tests, Android builds and a controlled field pilot before public launch.

This project is an implemented foundation with a deployed admin console, not yet a production-ready delivery service. Mark a task complete only after implementation and verification.
