# JIB Multi-Model AI Development Team — GitHub-native architecture

**Status:** GitHub workflow and bounded repository context are implemented on `feature/jib-ai-team-standalone`. Runner syntax check passed on 2026-11-20. Provider configuration and a successful four-model response run are still pending. A separate draft PR is required before the workflow can be enabled from GitHub Actions on the default branch.

## Goal

A development assistant in the GitHub repository, used across Customer, Merchant, Courier, and JIB Manager. It is a developer tool, not a JIB Manager runtime feature.

## Architecture

```
GitHub repository
  └── Actions: JIB AI Development Team (manual dispatch)
       └── GitHub-hosted runner
            └── .github/scripts/jib-ai-team.mjs
                 ├── bounded allowlisted repository context
                 ├── secret/PII redaction
                 ├── Architect model
                 ├── Implementation model
                 ├── Security model
                 └── QA model
                      └── downloadable report artifact
```

## Implemented safeguards

- Manual task execution only; a push to this feature branch runs syntax validation only.
- GitHub workflow permissions are read-only (`contents: read`).
- Context is loaded only from explicit allowlisted documentation and app entrypoints, with a 42,000-character total budget and per-file truncation.
- Secret redaction covers common API/GitHub/Supabase token formats, JWT-like tokens, email addresses, and phone numbers.
- HTTPS provider endpoint is required.
- Only model entries explicitly marked `free: true` are accepted; paid fallback is not implemented.
- Provider failures, quota/rate limits, and timeouts are reported; they do not trigger a paid fallback.
- No customer database rows, production secrets, environment files, or Supabase service-role credentials are included in repository context.
- No automatic repository writes, PR creation, merges, deployments, or database changes.
- A model majority cannot override approved JIB specifications. Disagreements and unknowns must be shown.
- Human owner approval is required for every proposed code change.

## Provider configuration still required

Configure these GitHub Actions values only after verifying the provider's terms, privacy, and free-tier conditions:

- `JIB_AI_TEAM_BASE_URL`: HTTPS OpenAI-compatible endpoint (FreeLLMAPI or an approved router).
- `JIB_AI_TEAM_API_KEY`: server-side GitHub Actions secret; never commit or paste it into source/chat.
- `JIB_AI_TEAM_FREE_MODELS_JSON`: repository variable containing exactly four explicit free model entries, each with a unique role from `architect`, `implementer`, `security`, `qa`, a model identifier, and `free: true`.

The runner accepts a generic OpenAI-compatible endpoint so FreeLLMAPI can serve both developer assistance and the planned JIB AI Manager integration after separate security review. This does not mean FreeLLMAPI or any gateway is already deployed or connected. The upstream FreeLLMAPI project documents a self-hosted gateway that aggregates third-party free provider tiers; it is not a hosted free API account. It requires a persistent host, an encryption key, and separately authorized upstream provider keys. Its own project README describes the project as personal experimentation and learning, not a stable production inference substrate. Therefore JIB must not use it for production customer data until hosting, security, privacy, terms, and continuity are independently approved. The JIB AI Manager route added to the application is advisory-only, HTTPS-only, server-side, and disabled until the three Vercel environment variables are configured.

## Provider/router evaluation order

- **OmniRoute:** primary routing candidate.
- **LiteLLM:** fallback/router candidate.
- **OpenRouter free models:** optional free model source, subject to current availability and terms.
- **FreeLLMAPI-Extended:** test candidate.
- **Bifrost, New API, One API:** alternatives to evaluate; do not deploy all routers simultaneously.

All candidates must be checked for free persistent hosting, license, provider terms, data handling, model availability, and enforceable no-billing behavior. No paid account, card, subscription, or paid fallback is permitted without explicit owner approval.

## Phases

1. **GitHub analysis team:** implemented; independent role reports and artifact output.
2. **Read-only repository context:** implemented with allowlisted files, bounded context, redaction, and file-path references requested in reports.
3. **Patch proposals:** not implemented; future patches must be artifacts or draft branches after separate review, never auto-merged.
4. **Quality gates:** app-specific Flutter/Next.js tests and security checks remain required for every accepted patch.
5. **Controlled pull requests:** only after explicit owner approval and least-privilege GitHub permissions.

## Important availability limitation

The workflow currently exists only in the independent AI-team PR #6, not the default branch. The push-triggered syntax validation works on this branch. GitHub requires the workflow to be present on the default branch for normal manual dispatch. Keep PR #6 Draft until the owner explicitly approves its review and merge; do not merge it merely to activate this workflow.


## GitHub activation and test state (2026-11-20)

- The workflow is isolated on `feature/jib-ai-team-standalone`; pushes run syntax validation only.
- The latest recorded validation run completed successfully. The multi-model job was skipped because it was a push event, not a manual dispatch.
- GitHub Actions requires a `workflow_dispatch` workflow to exist on the repository default branch before it can be manually dispatched from the Actions UI. This feature branch therefore needs a separate reviewed PR before the owner can dispatch it from GitHub Actions.
- No GitHub Actions secrets or repository variables are available through the connected GitHub actions in this session. Do not claim the models are connected. The owner must add the three values through GitHub Settings → Secrets and variables → Actions.
- Never place the API key in a repository variable, file, commit, issue, or chat. Store it only as `JIB_AI_TEAM_API_KEY` secret.
