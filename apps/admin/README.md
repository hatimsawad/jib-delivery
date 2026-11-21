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

Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in `.env.local`. For AI image generation, configure `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_API_TOKEN` as server-only environment variables in Vercel (Preview and Production as needed). Create a Cloudflare API token with Workers AI Read and Workers AI Write permissions. Never prefix these secrets with `NEXT_PUBLIC_`, put them in source control, or send them in chat.

## Current implementation

- Supabase SSR sign-in, password recovery and server-side admin-role verification.
- Live dashboard counts and read views for orders, stores, products and users.
- Admin RPC-backed store and courier approval actions.
- Order timeline, ETA, monitoring incidents, image review, brand catalog, and branch policy foundation.
- `/tracking`: admin-only courier location session and latest-point review. The courier app requires explicit consent; history is retained for 90 days and stale-location monitoring is cron-driven.
- `/ai-manager`: admin-only advisory chat adapter for FreeLLMAPI's OpenAI-compatible API. It has no SQL, tools, code execution, or operational write access; it redacts common secret/PII patterns, enforces a 20-message/hour per-admin limit through a private Supabase RPC, and has no paid fallback.

## AI Manager activation requirements

Set these server-only Vercel environment variables after verifying a genuinely free provider/model and its data-processing terms:

- `FREELLMAPI_BASE_URL` — HTTPS endpoint.
- `FREELLMAPI_API_KEY` — secret provider credential.
- `FREELLMAPI_FREE_MODEL` — explicitly verified free model identifier.

The chat route fails closed if the provider is missing, the rate-limit RPC is unavailable, the provider returns an error, or the free quota is exhausted. The SQL migration `20261120160000_jib_ai_manager_chat_rate_limit.sql` is committed on the feature branch but has not been applied to the live Supabase project. The chat must remain unavailable until that migration is reviewed and applied. Pattern-based redaction is not a guarantee; never submit customer records, passwords, credentials, or confidential information.

## Remaining production gates

- Complete authenticated route-by-route smoke tests and end-to-end order tests.
- Approve Rabat delivery zones, fees, commissions and exception rules; the temporary 15 MAD delivery fee must not be treated as final.
- Configure and test a free notification provider; paid SMS, WhatsApp and voice remain disabled.
- Verify Cloudflare image generation, storage and human review with an approved account plan.
- Complete security tests, leaked-password protection, backup/restore, commercial hosting review and release approval.
- Complete physical Android GPS/background validation and install-test all three release APKs.

## Safety

- All protected routes call server-side `requireAdmin()` or verify the admin role.
- Use RLS and admin-verified RPCs for every privileged mutation.
- Secrets belong in Vercel environment variables or a secrets manager, never Git.
- Destructive, financial, pricing, account-access and production-deployment actions require explicit human approval.
