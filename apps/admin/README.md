# JIB Manager

Standalone Arabic-first operations console for the JIB delivery platform in Rabat.

JIB Manager is deployed independently from the customer, merchant, and courier mobile apps. It shares the JIB Supabase project but has its own web entry point, admin-only authentication, and server-side authorization. The existing `apps/admin` directory is intentionally retained so the current Vercel project root and deployment configuration are not broken.

## Run locally

Requirements: Node.js 20.9+ and npm.

```bash
cd apps/admin
npm install
cp .env.example .env.local
npm run dev
```

Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in `.env.local`. For AI image generation, configure `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_API_TOKEN` as server-only environment variables in Vercel (Preview and Production as needed). Create a Cloudflare API token with Workers AI Read and Workers AI Write permissions. Never prefix these secrets with `NEXT_PUBLIC_`, put them in source control, or send them in chat. Image generation returns a clear setup error until both values exist.

## Current verified scope

- Supabase SSR sign-in, password recovery and server-side admin-role verification.
- Live dashboard counts for orders, pending orders, preparation, deliveries, active stores, products and active couriers.
- Read views for orders, stores, products and users.
- Admin RPC-backed store and courier approval actions.

## Not yet production-complete

Detailed order-stage timestamps and ETA, full dispatch controls, service zones and pricing, complete audit log, push/SMS/WhatsApp/voice provider delivery, maps, financial settlement, and AI-provider integration still require implementation and verification. The dashboard must not display these as active until the providers, secrets, database operations and tests are configured.

## Safety

- All protected routes call server-side `requireAdmin()`.
- Use RLS and admin-verified RPCs for every privileged mutation.
- Secrets belong in Vercel environment variables or a secrets manager, never Git.
- Destructive, financial, pricing, account-access and production-deployment actions require explicit human approval.
