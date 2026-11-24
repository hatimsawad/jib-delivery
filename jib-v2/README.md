# JIB V2 workspace

This directory is the isolated V2 implementation area. The legacy application directories and legacy Supabase migrations at repository root are frozen and must not be edited for V2.

## Applications
- `apps/customer`: Flutter Android customer app.
- `apps/merchant`: Flutter Android merchant app.
- `apps/courier`: Flutter Android courier app.
- `apps/admin`: private web administration app.

## Download the Android test apps

After the latest Android builds and checks pass, the APKs are published here:

https://github.com/hatimsawad/jib-delivery/releases/tag/jib-v2-downloads

- `JIB-Customer-debug.apk` — customer app.
- `JIB-Merchant-debug.apk` — merchant app.
- `JIB-Courier-debug.apk` — courier app.

These are debug builds for installation and acceptance testing, not signed production releases. The release is updated by the JIB V2 build workflow.

## Build checks
The GitHub Actions workflow `.github/workflows/jib-v2-build.yml` scaffolds Android platform files in the CI runner, builds all three APKs, runs Flutter analysis and widget tests, builds the admin web app, and publishes APK download assets after success. No production deployment is performed.

## Catalog snapshot

The JIB V2 catalogue currently contains **100 approved brands and 343 active product records**. 75 products currently have product images; 52 brands have website favicon marks. Reference prices and catalogue stock are not live branch offers. Merchants must confirm their own branch prices and stock before an item can be ordered.

The current catalogue expansion was sourced from public Marjane catalogue pages. It is not a Glovo import. Do not describe these records as Glovo-sourced. The catalogue is shared reference data; each branch still needs its own confirmed price and availability.

## Operational readiness

The V2 apps connect only to the independent JIB V2 Supabase project. The catalogue reference data is available, but the current database has no onboarded merchants, branches, branch-specific product offers, customer profiles, courier profiles, or orders. Consequently, the catalogue is not yet purchasable and a real order cannot yet complete end-to-end.

The administration web app has a READY staging deployment. This is not a production release. The Android APKs are debug builds, not signed production releases.

Delivery fee, merchant commission, and payment rules remain unconfigured until explicitly approved by the owner. Do not invent or activate commercial values. A real order can be accepted only after merchant branches and their confirmed product prices and stock are onboarded, user accounts are established, and the complete order lifecycle is tested.
