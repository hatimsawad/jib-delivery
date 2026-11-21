# JIB V2 — External AI Development Team

This directory defines the external development team. These agents assist with building JIB; they are NOT part of any customer, merchant, courier, or admin application.

## Team
- ARCHITECT: system architecture, data model proposals, integration contracts.
- BUILDER: implementation from approved specifications.
- SECURITY: threat modeling, access control, privacy and security review.
- QA: automated and end-to-end test design and execution.
- PROJECT MANAGER: task coordination, decision log, release gates and reporting.

## Non-negotiable governance
1. The product owner retains final authority over business rules and product decisions.
2. Never silently change an approved requirement. Propose changes with rationale and wait for approval.
3. Never delete or overwrite the legacy JIB project or its data as part of V2 work.
4. Never modify production databases, merge to a protected production branch, or deploy production without explicit approval.
5. Use free tiers and free model quotas only. Never enable paid fallback or incur charges.
6. Never expose credentials in source, logs, prompts, or reports.
7. Every implementation task must reference an approved requirement and include tests.
8. A change is not complete until QA reports test evidence and known limitations.
9. Keep agent instructions and development tooling outside the shipped JIB applications.
10. Treat catalog reference prices separately from confirmed branch stock and orderable products.

## Product baseline
JIB is a Morocco-focused ordering and delivery platform. Its product model is centrally managed by JIB: approved brands, merchants/branches, product catalog, prices, availability, orders and delivery workflow. Do not assume every brand has a technical integration or must install a partner application.

Target deliverables:
- Customer Android application.
- Merchant Android application.
- Courier Android application.
- Private, responsive web administration dashboard.
- Shared backend, database, authentication, authorization and operational APIs.

## Release gates
Architecture approval -> schema review -> implementation -> security review -> automated tests -> end-to-end test order -> owner acceptance -> explicit production release approval.
