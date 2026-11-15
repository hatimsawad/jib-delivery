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
- Six original Supabase migrations plus the new client-grants hardening migration. The current Supabase migration history contains eight entries; the `tighten_client_table_grants` name appears twice under separate versions (idempotent SQL).

## Live Supabase project

- Project: JIB; ref: `emvleaghjsmzjmzgguvu`; region: `eu-west-3` (Paris).
- Seven public application tables have Row Level Security enabled: profiles, stores, products, addresses, orders, order_items and order_events.
- A confirmed Supabase Auth user with the `admin` profile role exists.
- Supabase URL and publishable key are configured in Vercel for production, preview and development.
- Checkout RPC validates the signed-in customer, address ownership, active/open store, product availability and quantities; it reads prices from the database and creates order and item records transactionally.
- Direct client writes to orders/order_items/order_events are not allowed.
- Client table grants were hardened: authenticated users can read RLS-filtered rows; merchants can write stores/products only through owner-scoped RLS; customers can manage their own addresses; users can update only profile name, phone and language.
- Verified database privileges: authenticated cannot update profile role, cannot insert orders directly, and anonymous users cannot read stores. Authenticated profile-name edits, store/product inserts and address inserts are permitted subject to RLS.
- Trigger-only SECURITY DEFINER functions have direct API execution revoked.

## Confirmed blockers and security review

- Password recovery email is not reliable yet. Supabase Auth logs on 2026-11-15 show Google SMTP authentication failure `535 5.7.8 Username and Password not accepted`. Earlier attempts hit `429 email rate limit exceeded` on the built-in sender. The recovery form and callback routes exist; mail transport must be corrected before recovery is verified end-to-end.
- A Google App Password-like value was previously exposed in chat. Revoke it in Google Account security settings and create a replacement. Never commit SMTP credentials to Git or paste them into chat.
- Supabase Security Advisor still reports two authenticated-callable SECURITY DEFINER functions: `checkout_order` (intended authenticated checkout endpoint) and `is_jib_admin` (used by admin RLS policies). Review and adversarially test these before public launch.
- Supabase Security Advisor reports leaked-password protection disabled.
- Performance Advisor reports RLS init-plan and multiple permissive-policy optimization opportunities. These are performance warnings, not by themselves evidence of a data leak.
- The checkout function currently uses a temporary 15 MAD delivery fee. This must be replaced with a validated pricing and service-area model.
- Current application data is empty for stores, products and orders. A public customer launch would therefore have no merchant inventory to serve.
- Customer, merchant and courier Flutter apps remain visual starters with placeholder/sample content; live authentication, API integration, cart, order processing, merchant order management, courier dispatch and tracking are not complete.
- No signed production APK/AAB, payment gateway, production maps, push notifications, courier dispatch or live tracking is complete.

## Next engineering tasks

1. Correct Supabase Auth SMTP and URL allow-list, then test one recovery email and password-reset session end-to-end.
2. Test deployed admin login and each admin list route using the already-provisioned admin account.
3. Connect the three Flutter apps to Supabase Auth and the live schema, replacing placeholder stores and sample data.
4. Add safe, database-authorized merchant order acceptance/state transitions and courier assignment/availability operations with audit events.
5. Decide the delivery fee and Rabat service zones; remove the temporary 15 MAD fee from checkout.
6. Add maps, notifications, payment integration after provider approval, automated tests, Android builds and a controlled field pilot before public launch.

This project is an implemented foundation with a deployed admin console, not yet a production-ready delivery service. Mark a task complete only after implementation and verification.
