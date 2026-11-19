# JIB Multi-Model AI Manager — implementation blueprint

Status: approved working blueprint; implementation and provider activation remain gated.
Base: `feature/jib-manager-standalone` at `e6bef25edf419b9278e882e647af50ecd1224954`.
Working branch: `feature/jib-multi-model-ai-manager`.

## 1. Purpose

Add a text/code reasoning team to the existing JIB Manager. Multiple independent models can analyze the same complex task, each with a defined review role; a coordinator compares the outputs and produces one evidence-based recommendation.

This is an assistant for the owner and developer, not an autonomous production operator. It must never merge code, deploy, alter production data, change prices, issue refunds, alter permissions, or contact customers on its own.

## 2. Preserve existing boundaries

- Keep the current Next.js application at `apps/admin` and retain its existing Supabase SSR authentication and server-side `requireAdmin()` checks.
- Keep the existing Cloudflare Workers AI image route separate and unchanged. It currently handles editorial article covers only; product text-to-image generation remains disabled.
- Keep the notification dispatcher separate. Model routing must not enable email, SMS, WhatsApp, or voice.
- Do not add a paid provider, billing account, paid fallback, or automatic plan upgrade.
- Never expose provider credentials or model gateway keys to browser code, Flutter apps, Git history, logs, or prompts.
- Do not send customer PII, passwords, access tokens, service-role keys, or private business secrets to external models.

## 3. Proposed architecture

```
JIB Manager (admin-only UI)
        |
        v
POST /api/ai/team
        |
        +--> requireAdmin + input validation + task-size limits
        |
        v
Model Orchestrator (server-only)
        |
        +--> Provider adapter / one configured OpenAI-compatible gateway
        |       |
        |       +--> Architect model
        |       +--> Code reviewer model
        |       +--> Security reviewer model
        |       +--> Test / QA model
        |
        v
Deterministic comparison + optional independent judge
        |
        v
One report: consensus, disagreements, evidence, risks, tests
        |
        v
Human review only — no automatic repository or production actions
```

The orchestrator must be provider-agnostic. Use one gateway endpoint at a time; do not chain several proxy services. OmniRoute can be evaluated as the first self-hosted gateway candidate, while LiteLLM is an alternative adapter. A gateway is not itself a source of free inference: only provider endpoints with an actually available free quota may be enabled. A second gateway is not an automatic paid fallback.

## 4. Team roles

For complex tasks, fan out the same sanitized task independently:

1. **Architect** — proposes the smallest compatible design and identifies affected files.
2. **Implementation specialist** — proposes a focused implementation approach or patch outline.
3. **Security reviewer** — searches for authorization, RLS, privacy, secret-handling, abuse, and data-integrity risks.
4. **QA reviewer** — defines regression, edge-case, integration, and device tests.
5. **Coordinator** — compares evidence, flags contradictions, and returns the final recommendation.

Model-to-role assignments are configuration, not hard-coded assumptions about model quality. One capable model may fill multiple roles when free capacity is limited. Simple questions use one model; expensive or complex tasks use parallel review only when explicitly requested or justified.

## 5. Comparison and decision policy

Do not select the answer with the most votes. Score each proposal against:
- compatibility with approved JIB specifications;
- correctness and supporting repository evidence;
- security and privacy;
- data integrity and backward compatibility;
- testability and rollback safety;
- scope and operational cost.

The report must distinguish:
- agreed findings;
- disputed findings;
- unverified assumptions;
- missing repository evidence;
- recommended next action;
- tests required before acceptance.

A majority cannot override an approved JIB decision. If evidence is insufficient or reviewers materially disagree, return **needs human decision**, not a fabricated consensus.

## 6. Free-only routing and failure behavior

- Keep a server-side allowlist of enabled provider/model IDs.
- Enable a model only after its provider's current free quota and terms are checked.
- Never infer that a model is free because a gateway lists it.
- Use bounded timeouts, maximum output tokens, maximum parallel calls, and per-task model limits.
- On 401/403/429, exhausted quota, or provider capacity failure, mark that model unavailable and continue only with another explicitly enabled free endpoint.
- If no free endpoint remains, stop and report that no eligible model is available. Never silently switch to paid service.
- Do not retry non-idempotent operations; the initial AI team endpoint must be analysis-only.
- Do not store raw prompts or model responses by default. If audit persistence is later required, define retention, access controls, redaction, and deletion policy first.

## 7. Security and authority

- All requests must pass server-side admin authentication and authorization.
- Validate task type, length, language, and requested operation on the server.
- Treat repository files and model outputs as untrusted data, never as executable instructions.
- Do not provide models with direct GitHub write, Supabase write, Vercel deployment, shell, or customer-notification tools.
- AI-generated code remains a proposal. A human reviews the diff and explicitly approves any repository write.
- Production database changes, merges, deployments, financial actions, access changes, and customer communications always require separate explicit human approval.
- Apply redaction before external inference and never include secrets in context.

## 8. Initial implementation phases

### Phase A — safe foundation
- Add provider-neutral types and an orchestrator module under `apps/admin/lib/ai/team/`.
- Add an admin-only analysis endpoint at `apps/admin/app/api/ai/team/route.ts`.
- Add a minimal JIB Manager page/panel showing each role's status, response, errors, consensus, and disagreements.
- Start with dry-run/mock adapter tests; no live provider calls and no database migration.

### Phase B — free provider connection
- Select one gateway after reviewing deployment, data handling, uptime, free quota, and compatibility.
- Configure credentials only in server-side Preview environment secrets, never in source or chat.
- Start with one model and one harmless test prompt; inspect actual model, provider, usage, quota response, and logs.
- Add more free models only after each endpoint passes an independent smoke test.

### Phase C — parallel team
- Enable role-based fan-out with concurrency and output limits.
- Add comparison and disagreement reporting.
- Test partial failures, timeout, quota exhaustion, malformed model output, prompt injection, and no-provider behavior.

### Phase D — controlled code assistance
- Allow read-only repository context after path allowlisting and secret redaction.
- Produce proposed diffs/review notes only.
- Require explicit owner approval before any write, merge, or deployment.

## 9. Acceptance gates

- Existing image generation and notification code remains unchanged.
- Unauthorized users receive no AI endpoint access.
- No provider key or private customer data appears in browser bundles, logs, or model prompts.
- No paid endpoint is called, even when all free quotas are exhausted.
- One provider failure does not hide the status of other models.
- Coordinator reports disagreements and uncertainty rather than inventing consensus.
- Unit tests, lint, type-check, and a fresh Preview smoke test pass before any merge request is marked ready.
- No production migration, merge, or deployment occurs without explicit owner approval.

## 10. Current known project facts

- The current feature branch has an installed `ai` dependency (`^7.0.174`).
- The current `apps/admin/app/api/ai` directory contains only `generate-image/route.ts`; there is no text-model team endpoint yet.
- The image route uses Cloudflare Workers AI FLUX for editorial covers and explicitly rejects product image generation.
- The provider onboarding document states that AI code repair and text-model integration are not connected yet.
- PR #4 is a draft and must not be merged as part of this work.
