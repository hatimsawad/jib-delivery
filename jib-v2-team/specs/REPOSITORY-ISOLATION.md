# JIB V2 — Repository Isolation Rules

Status: Mandatory development boundary.
Branch: `jib-v2-bootstrap`.

## Current repository fact
This branch was created from the existing repository's `main` branch. Therefore it contains pre-existing legacy paths such as `apps/customer`, `apps/merchant`, `apps/courier`, `apps/admin` and `supabase/migrations`. Their presence in this branch does not make them V2 code and does not authorize modifying them.

## Protected paths
Treat all existing paths inherited from the base branch as frozen unless the owner explicitly approves a specific change. In particular:
- `apps/customer/`
- `apps/merchant/`
- `apps/courier/`
- `apps/admin/`
- `supabase/`
- Existing workflows and deployment configuration

Do not run legacy migrations, connect a V2 client to the legacy Supabase project, change production secrets, or deploy legacy code as V2.

## V2 source boundary
All new V2 application source, backend definitions, tests and build configuration must be created under a new top-level `jib-v2/` directory. New CI workflows must use V2-only paths and isolated test resources. The `jib-v2-team/` directory is planning/documentation only.

## Backend boundary
A dedicated V2 backend project must be provisioned and its project identifier verified before any schema migration or data seeding. Do not infer that a configured legacy project is safe to reuse. Never copy BLACKNESS or customer personal data into V2 as part of development.

## Review gate
Before any change touches a protected path or any existing remote service, stop and obtain explicit owner approval. A pull request, staging deployment or production release is not automatically authorized by this branch approval.

## Acceptance
A reviewer must be able to verify from the Git diff that V2 implementation commits add/change only `jib-v2/` and V2-specific documentation/workflows, with no edits to protected legacy paths.
