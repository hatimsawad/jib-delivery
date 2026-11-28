# JIB V2 workspace

This directory is the isolated V2 implementation area. The legacy application directories and legacy Supabase migrations at repository root are frozen and must not be edited for V2.

## Applications
- `apps/customer`: Flutter Android customer app.
- `apps/merchant`: Flutter Android merchant app.
- `apps/courier`: Flutter Android courier app.
- `apps/admin`: private web administration app.

## Android test builds

The current GitHub Actions workflow builds customer, merchant and courier Debug APKs and runs Flutter analysis/tests plus the admin web build. The latest verified run is:

https://github.com/hatimsawad/jib-delivery/actions/runs/45439566956

The APKs are Debug builds for acceptance testing. They are not signed production releases. The workflow's public release-publishing job was skipped in the latest run; do not promise a public APK download until a release is present.

## Live catalogue snapshot — 2026-11-28

The isolated JIB V2 database currently contains:
- 100 brand records and 343 active product records.
- 216 products with a positive reference price; 127 without one.
- 75 products with an image URL; 268 without one.
- 273 product records marked as draft source templates and 34 products without a brand assignment.
- 293 products in the food-category allowlist used by the customer app. Another 50 records in non-food categories (including household, fashion, electronics, sports/outdoors and personal care) are not currently loaded by that app.

A reference price is not a verified branch selling price. A product image URL is not proof that JIB has rights to reuse that image. Source metadata must be checked per asset: some brand records specify permission for JIB catalog reuse, while other records specify only brand-name/public-URL metadata. Do not expand image reuse beyond the recorded permission. Do not describe all 343 records as a complete Glovo catalogue.

## Live operational snapshot — 2026-11-28

The database currently has:
- 3 direct-purchase merchant records and 9 branch records (8 branches active).
- 0 merchant owner-user links; the existing store records are not yet connected to merchant login accounts.
- 0 branch-specific product offers in `branch_products`.
- 2 profiles total (1 admin and 1 customer); no courier profile was present in the role summary.
- 0 orders.

Therefore products can be browsed as catalogue references, but no product is currently purchasable through a confirmed branch offer and a real customer order has not yet been completed. Do not seed fake branch prices, stock or merchant accounts to make the UI look ready.

## Current application limitations to close

- Customer: search is currently client-side over the loaded catalogue; only the food-category allowlist is fetched. Product cards show a reference price or indicate that branch price is not confirmed. Cart and order RPC require a selected branch with confirmed, available branch offers. Delivery fee is not quoted from distance before confirmation; delivery coordinates are not supplied from the current address form.
- Merchant: catalogue products can be confirmed one at a time for a branch; the app requires a merchant account linked by `owner_user_id`. Existing direct-purchase merchant records have no owner link.
- Courier: accepts offers and records the actual purchase amount and customer cash collection. Background location sharing/foreground service, map navigation, receipt image upload and proof-of-delivery are not implemented in the current courier screen.
- Admin: can manage brand/product visibility and reference catalogue fields, onboard profiles, create/activate branches, set an order's delivery fee manually, dispatch couriers and mark settlement steps. It does not yet provide bulk catalogue import, product image upload, branch-wide price/availability management, or distance-based delivery-fee quotation.
- Storage: the JIB V2 Storage bucket query currently returns no buckets, so product-image upload/storage is not configured.
- Security: the Supabase security advisor reports that leaked-password protection is disabled. Enable it before production use.

## Release readiness

The Vercel production deployment for `jib-v2-admin-live` is READY on `main`, but that does not prove the admin workflow has been acceptance-tested with a real owner account. Android artifacts are Debug builds only. A signed production release, physical-device installation/upgrade test, merchant/courier account onboarding, confirmed branch prices and stock, full order E2E, delivery-fee quote, background location consent test and financial reconciliation are still required.

Keep commercial rules unchanged: JIB product price is the verified base/reference price plus 2 MAD exactly once; never apply the markup twice. Keep branch/product availability explicitly confirmed and do not invent prices, images, stock, permissions or delivery fees.
