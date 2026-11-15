# JIB implementation status

Last updated: 2026-11-15

## In repository

- Product specification, architecture, roadmap and security review.
- Initial PostgreSQL schema and follow-up hardening migrations.
- Next.js admin dashboard scaffold with Arabic RTL layout and JIB brand colors.
- Placeholder project folders for customer, courier and merchant Flutter apps.
- Supabase setup notes and environment-variable template.
- Trusted SQL checkout function: validates authenticated customer, address ownership, active/open store, product availability and quantities; calculates totals from stored prices; creates order, items and initial event in one database transaction.
- Profile role trigger prevents normal authenticated users from self-assigning privileged roles.

## Not yet done / not verified

- No live Supabase project has been connected; migrations are not applied.
- No real authentication screens or admin authorization flow yet.
- No customer, courier or merchant Flutter application source implementation yet; their folders currently contain planning notes only.
- No payment gateway, maps, push notifications, courier dispatch or live tracking.
- No dependency installation, automated test run, production build, APK/AAB or deployment has been performed.

## Next engineering tasks

1. Apply migrations to a disposable Supabase project and test checkout and role protection with multiple accounts.
2. Add admin authentication and server-side authorization before exposing dashboard data.
3. Implement merchant and customer app flows against the tested backend.
4. Add courier assignment and permitted order-state transition functions.
5. Add CI checks and a reproducible Android build pipeline.


## UI and automation additions (2026-11-15)

- Added runnable Flutter project manifests and starter screens for customer, courier and merchant roles.
- Customer screen includes Arabic RTL discovery, categories, sample store cards and navigation shell.
- Courier and merchant screens establish the initial operational navigation and placeholder states.
- Added GitHub Actions workflow to analyze all Flutter apps and build the Next.js admin dashboard on pushes and pull requests.
- Updated root README with workspace map.

These are starter implementations, not launch-ready applications. The CI workflow has been committed but has not yet been observed running successfully.
