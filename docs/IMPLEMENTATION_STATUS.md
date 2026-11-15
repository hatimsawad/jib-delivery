# JIB implementation status

Last updated: 2026-11-15

## Confirmed in GitHub

- Product specification, architecture, roadmap and setup documentation.
- Flutter starter projects for customer, courier and merchant roles.
- Next.js Arabic RTL admin app with Supabase SSR authentication, login, password-reset request, callback and password-update routes.
- Admin dashboard routes for overview, orders, stores, products and users. These are read-only operational views backed by Supabase and require an admin session.
- GitHub Actions CI workflow. A previously verified run passed the admin build and all three Flutter analyze/widget-test jobs.
- Six ordered Supabase migrations, including the initial schema, checkout hardening, role protection, admin read policies, auth profile trigger, trigger-function grants and foreign-key indexes.

## Live hosting and Supabase

- Supabase project: JIB, ref `emvleaghjsmzjmzgguvu`, region `eu-west-3` (Paris).
- All six migrations are present in Supabase migration history.
- Seven public application tables have Row Level Security enabled: profiles, stores, products, addresses, orders, order_items and order_events.
- A confirmed Supabase Auth user with the `admin` profile role exists.
- Supabase URL and publishable key are configured in Vercel for production, preview and development.
- Vercel project `jib-admin` is connected to `hatimsawad/jib-delivery`. The previous production deployment was READY. New admin views were subsequently committed and are awaiting their latest deployment verification.
- Checkout RPC validates the signed-in customer, address ownership, active/open store, product availability and quantities; it reads prices from the database and creates the order and items transactionally.
- Direct client writes to order/order-item/order-event tables are revoked.
- Trigger-only SECURITY DEFINER functions have direct API execution revoked.

## Confirmed blockers and security review

- Password recovery email is not currently reliable. Supabase Auth logs on 2026-11-15 show Google SMTP authentication failure `535 5.7.8 Username and Password not accepted` at 10:18 UTC. Earlier attempts hit `429 email rate limit exceeded` on the built-in sender. The recovery form and callback routes exist; the mail transport must be corrected before recovery can be verified end-to-end.
- Google SMTP app passwords must be managed privately by the account owner; credentials must never be committed to Git or pasted into chat. A previously shared app-password-like value should be revoked and replaced.
- Supabase Security Advisor reports two authenticated-callable SECURITY DEFINER functions: `checkout_order` (intended authenticated checkout endpoint) and `is_jib_admin` (used by admin RLS policies). Review and test these before public launch.
- Supabase Security Advisor reports leaked-password protection disabled.
- Performance Advisor reports RLS init-plan and multiple permissive-policy optimization opportunities. These are performance warnings, not by themselves evidence of a data leak.
- The checkout function currently uses a temporary 15 MAD delivery fee. This must be replaced with a validated pricing and service-area model.
- Current application data is empty for stores, products and orders. A public customer launch would therefore have no merchant inventory to serve.
- Customer, merchant and courier Flutter apps remain visual starters with placeholder/sample content; live authentication, API integration, cart, order processing, availability, dispatch and tracking are not complete.
- No signed production APK/AAB, payment gateway, production map provider, push notifications, courier dispatch or live tracking is complete.

## Next engineering tasks

1. Resolve Supabase Auth SMTP using a valid private credential; confirm the deployed callback URL is allow-listed and test one recovery email.
2. Verify the new admin routes in the latest Vercel deployment and test admin login using the already-provisioned admin profile.
3. Connect the three Flutter apps to Supabase Auth and the live schema, replacing all placeholder stores and sample data.
4. Add safe admin/merchant product and store management, order-state transitions and courier assignment with database-side authorization and audit events.
5. Decide the delivery fee and Rabat service zones; remove the temporary fee from checkout.
6. Add maps, notifications, payment integration (after provider agreement), automated tests, Android builds and a controlled field pilot before public launch.

This project is a working foundation, not yet a production-ready delivery service. Mark a task complete only after implementation and verification.
