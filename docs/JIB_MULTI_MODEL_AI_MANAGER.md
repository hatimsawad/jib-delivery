# JIB Multi-Model AI Development Team — GitHub-native architecture

Status: implementation moved to GitHub Actions on `feature/jib-multi-model-ai-manager`.

## Goal

A development assistant in the GitHub repository, used across Customer, Merchant, Courier, and Manager applications. It is not a JIB Manager product feature.

## Architecture

```
GitHub repository
  └── Actions: JIB AI Development Team (manual dispatch)
       └── GitHub-hosted runner
            └── .github/scripts/jib-ai-team.mjs
                 ├── Architect model
                 ├── Implementation model
                 ├── Security model
                 └── QA model
                      └── downloadable report artifact
```

## Authority and safety

- Manual invocation only in the first phase.
- Read-only GitHub workflow permissions.
- Free models only; no paid fallback.
- No provider credentials in source code.
- No customer or production secrets in prompts.
- No automatic repository writes, PR creation, merges, deployments, or database changes.
- The human owner approves every proposed code change.
- A model majority cannot override approved JIB specifications.
- Disagreements and unknowns must be shown rather than hidden behind a false consensus.

## Phases

1. **GitHub analysis team:** independent role reports, free-only provider routing, artifact output.
2. **Read-only repository context:** explicitly allowlisted files, secret scanning/redaction, bounded context, and source citations.
3. **Patch proposals:** create a patch artifact or draft branch only after a separately reviewed design; never auto-merge.
4. **Quality gates:** app-specific Flutter/Next.js tests, static analysis, security checks, and human review.
5. **Controlled pull requests:** only after explicit approval and least-privilege GitHub permissions.

The GitHub Actions workflow must remain separate from the JIB Manager runtime. JIB Manager's existing image-generation and notification responsibilities remain unchanged.
