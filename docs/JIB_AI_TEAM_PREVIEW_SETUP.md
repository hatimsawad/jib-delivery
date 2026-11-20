# JIB AI Development Team — GitHub Actions

## Purpose and location

The multi-model development team belongs to this GitHub repository, not to JIB Manager. It is a repository development tool used to plan, review, secure, and test all four JIB applications:

- Customer app
- Merchant app
- Courier app
- JIB Manager

The entry point is the GitHub Actions workflow `.github/workflows/jib-ai-team.yml`. The runner and orchestration script live in `.github/scripts/jib-ai-team.mjs`.

## How to run

1. Open the JIB repository on GitHub.
2. Open **Actions**.
3. Select **JIB AI Development Team**.
4. Select the application scope (or `all`), enter a task, and run the workflow.
5. Open the completed run and download the `jib-ai-team-report` artifact.

The workflow is manually dispatched for model analysis. A push to `feature/jib-ai-team-standalone` runs syntax validation only; it does not contact a model. The model job requires the three provider values below. The workflow file must first be present on the repository's default branch before it appears as a normal manual workflow in GitHub Actions. Until then, keep this implementation on its feature branch.

## Roles

- Architect: smallest compatible design and affected areas.
- Implementer: concrete implementation plan and proposed file changes.
- Security: authentication, authorization, RLS, privacy, secrets, and data integrity.
- QA: regression, integration, edge-case, and platform test plan.

The current version returns independent reports. It does not claim consensus and does not edit files, open PRs, merge, deploy, execute SQL, or access live Supabase data. It reads only an explicit allowlist of repository documentation and app source files from `feature/jib-manager-standalone`, with a 42,000-character total limit. Those excerpts and the task are sent to the configured provider after basic secret, email, phone, and JWT-like pattern redaction. Pattern redaction is not perfect; never submit confidential or customer data. Repository writes remain prohibited.

## Free-only configuration

Configure these under GitHub repository **Settings → Secrets and variables → Actions**:

- Variable `JIB_AI_TEAM_BASE_URL`: OpenAI-compatible gateway base URL (without `/chat/completions`).
- Secret `JIB_AI_TEAM_API_KEY`: provider credential.
- Variable `JIB_AI_TEAM_FREE_MODELS_JSON`: JSON array of exactly four explicitly approved models, for example:

```json
[
  { "role": "architect", "model": "provider/model-a", "free": true },
  { "role": "implementer", "model": "provider/model-b", "free": true },
  { "role": "security", "model": "provider/model-c", "free": true },
  { "role": "qa", "model": "provider/model-d", "free": true }
]
```

The `free: true` flag is an operator allowlist assertion, not proof of free usage. Verify current provider pricing, free quotas, rate limits, retention, and data-processing terms before enabling a model. Do not enable any paid fallback, billing, or automatic upgrade. When the free quota is exhausted, that model is reported unavailable.

## Security boundaries

- Workflow permissions are read-only (`contents: read`); checkout credentials are not persisted.
- The workflow is manual-only and has no pull-request event trigger.
- Provider credentials are read from GitHub Actions secrets, never committed.
- Do not submit customer PII, credentials, tokens, private merchant information, or production secrets. Basic pattern redaction is not a complete privacy filter.
- Only allowlisted source/specification excerpts and the task are sent to the provider after pattern redaction. The allowlist excludes environment files, secrets, database rows, and production records.
- Model responses are untrusted suggestions and require human verification.
- No automatic source changes, PR creation, merge, production database action, or deployment is permitted.

## Current status

This GitHub Actions implementation is a safe first stage. The latest syntax validation run `44767158256` passed. The actual multi-model job was skipped because the event was a push, not a manual dispatch. Provider variables and secret are not verified as configured, so no successful live four-model run is claimed. This independent branch contains only the GitHub development assistant and its documentation; JIB Manager remains in PR #4.
