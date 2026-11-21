# JIB V2 workspace

This directory is the isolated V2 implementation area. The legacy application directories and legacy Supabase migrations at repository root are frozen and must not be edited for V2.

## Applications
- `apps/customer`: Flutter Android customer app.
- `apps/merchant`: Flutter Android merchant app.
- `apps/courier`: Flutter Android courier app.
- `apps/admin`: private web administration app.

## Build checks
Use the manual GitHub Actions workflow `.github/workflows/jib-v2-build.yml`. It scaffolds Android platform files in the CI runner, builds the three APKs, builds the admin web app, and uploads build outputs. No production deployment is performed.

## Important
These are initial V2 foundations, not release-ready applications. Authentication, backend integration, live order flow, catalog data, dispatch, notifications and security policies must be implemented and tested before release. Do not point them at the legacy Supabase project.
