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

The workflow is manually dispatched only. It does not run on pull requests, pushes, or production deployments. The workflow file must first be present on the repository's default branch before it appears as a normal manual workflow in GitHub Actions. Until then, keep this implementation on its feature branch.

## Roles

- Architect: smallest compatible design and affected areas.
- Implementer: concrete implementation plan and proposed file changes.
- Security: authentication, authorization, RLS, privacy, secrets, and data integrity.
- QA: regression, integration, edge-case, and platform test plan.

The first version returns independent reports. It does not claim consensus and does not edit files, open PRs, merge, deploy, or access Supabase. A later, separately reviewed phase may add allowlisted read-only repository context and proposed patch artifacts; repository writes must remain behind explicit human approval.

## Free-only configuration

Configure these under GitHub repository **Settings → Secrets and variables → Actions**:

- Variable `JIB_AI_TEAM_BASE_URL`: OpenAI-compatible gateway base URL (without `/chat/completions`).
- Secret `JIB_AI_TEAM_API_KEY`: provider credential.
- Variable `JIB_AI_TEAM_FREE_MODELS_JSON`: JSON array of up to four explicitly approved models, for example:

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
- This initial phase sends only the task text and selected application scope. It does not send repository source files to the provider.
- Model responses are untrusted suggestions and require human verification.
- No automatic source changes, PR creation, merge, production database action, or deployment is permitted.

## Current status

This GitHub Actions implementation is a safe first stage. Provider variables and secret are not configured by this commit, so it will not contact any model until the owner deliberately configures them. It has not been run against a live provider. The old JIB Manager UI/API implementation is removed from this branch; the existing image-generation and notification features are not part of this tool.
