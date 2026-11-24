# JIB V2 Admin

Private operations dashboard for JIB V2.

## Deployment
- Framework: Next.js
- Runtime: Node.js 22
- Vercel project root: `jib-v2/apps/admin`
- Git preview deployments are built from pushes to `jib-v2-bootstrap`.

## Owner access
- The first owner account is created from the dashboard login screen.
- Registration is restricted to the pre-authorized JIB owner email.
- The owner email must be confirmed by Supabase Auth before the one-time owner bootstrap RPC can grant the admin role.
- Other accounts cannot self-assign the admin role.
- The legacy JIB project and its user credentials are not modified.

## Security
- Client uses only the Supabase publishable key.
- Authorization is enforced by Supabase Auth, row-level security, and the one-time owner bootstrap function.
- Never put Supabase service-role keys in this application or its browser bundle.

## Brand system
- Approved JIB identity: vivid red, Moroccan green, white, and charcoal black.
- Red is the primary action color; green marks confirmation, delivery, and the Moroccan star.
- White/light-neutral surfaces keep the catalogue readable; Arabic RTL is the default.
