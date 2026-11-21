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

## Operational readiness
The V2 apps connect only to the independent JIB V2 Supabase project. Catalog reference data is available, but actual merchant branches, branch-specific prices and stock must be confirmed by the respective merchants. Delivery fee and payment rules remain unconfigured until approved. A real order cannot be accepted until an active merchant branch and confirmed products are onboarded and the full order lifecycle is tested.
