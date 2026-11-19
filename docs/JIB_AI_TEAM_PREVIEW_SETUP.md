# JIB AI Team — Preview configuration

This feature is intentionally inert until an administrator configures all required server-side variables.

## Required environment variables

- `JIB_AI_TEAM_BASE_URL`: base URL of one OpenAI-compatible chat-completions gateway. Do not include the `/chat/completions` suffix.
- `JIB_AI_TEAM_API_KEY`: provider credential. Keep it in Vercel Preview environment secrets only; never commit it or place it in Flutter/browser variables.
- `JIB_AI_TEAM_FREE_MODELS_JSON`: JSON array of explicitly approved model entries, for example:

```json
[
  { "role": "architect", "model": "provider/model-a", "free": true },
  { "role": "implementer", "model": "provider/model-b", "free": true },
  { "role": "security", "model": "provider/model-c", "free": true },
  { "role": "qa", "model": "provider/model-d", "free": true }
]
```

The `free: true` field is an explicit operator assertion, not automatic proof that a model is free. Before enabling any entry, verify the provider's current free quota, rate limits, data-processing terms, retention policy, and that the model does not require credits or paid billing. A gateway's free-model label alone is not sufficient evidence.

## Safety rules

- Configure these variables in a Preview environment only until the feature has passed review.
- Use one gateway endpoint; do not chain gateways.
- No paid fallback is implemented. A 429 or exhausted quota is returned as a failed model result.
- The API is admin-only and analysis-only. It has no repository, Supabase, Vercel deployment, shell, or customer messaging tools.
- Results are not stored in the database.
- Basic redaction catches common API-token patterns, emails, and phone numbers; it is not a complete privacy filter. Never submit customer information, credentials, access tokens, private merchant information, or other sensitive data.
- No model call occurs when the model allowlist or provider credentials are missing.
- The model allowlist accepts at most four entries and only the four declared review roles.

## Current implementation boundary

The first slice provides an admin-only page and an analysis endpoint. It returns independent role outputs and does not claim consensus. The deterministic comparison/judge, provider health checks, rate limiting, automated tests, and repository read-only context are still pending. Do not enable this in Production or mark it release-ready until those gates are implemented and tested.
