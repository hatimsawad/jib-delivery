# JIB External AI Development Team v2

This is an external engineering tool for the JIB repository. It is not embedded in Customer, Merchant, Courier, or Manager apps.

## What it does
1. Architect model analyzes the task and bounded source context.
2. Implementer model proposes a real unified diff.
3. Security and QA models independently review that proposed diff.
4. The runner validates the patch with `git apply --check` and uploads the patch and report as a GitHub Actions artifact.

The runner never applies a patch, writes to JIB source, creates commits, opens PRs, merges, deploys, or accesses production databases. Human approval remains mandatory.

## Run
GitHub Actions → **JIB External AI Development Team** → choose scope, task, and source branch. Download `jib-ai-development-proposal`.

## Required Actions configuration
- `JIB_AI_TEAM_BASE_URL` — HTTPS OpenAI-compatible endpoint.
- `JIB_AI_TEAM_API_KEY` — Actions secret only.
- `JIB_AI_TEAM_FREE_MODELS_JSON` — exactly four unique roles: architect, implementer, security, qa; each explicitly marked `free: true`.

The free flag is an allowlist declaration, not proof of provider pricing. Confirm quotas, retention, and no-billing behavior. No paid fallback is implemented. Never submit credentials, customer data, or production secrets.

## Current activation constraint
GitHub requires a workflow_dispatch workflow to be present on the default branch before it can be launched normally from Actions. This branch can run syntax validation on push. Keep the PR Draft until owner review; do not merge or deploy without explicit approval.
