# JIB V2 — Technical Architecture Proposal

Status: Proposed architecture, not a production deployment or schema migration.
Branch: `jib-v2-bootstrap`.

## 1. Isolation first
JIB V2 must be developed as an isolated system. The legacy JIB project, legacy Supabase project, BLACKNESS account and existing records are out of scope and must remain unchanged.

Before selecting or provisioning any backend resource, verify the target project identifier and environment. Use a dedicated V2 staging project and separate credentials. Never point V2 development clients at the legacy production database.

## 2. Logical components
- Customer Android client.
- Merchant Android client.
- Courier Android client.
- Private admin web client.
- Backend API/authentication layer.
- Relational database for users, roles, merchants, branches, catalog, inventory, orders and events.
- Object storage for approved media/proof files, if required.
- Notification delivery service.
- Optional location/event ingestion for active courier jobs only.

A shared backend is the source of truth. Clients must not directly mutate protected order state or privileged records.

## 3. Suggested domain boundaries
- Identity & access: users, sessions, roles, scoped memberships.
- Commerce catalog: brands, product references, sources and media.
- Branch operations: branch-specific sellable items, prices and availability.
- Orders: immutable order snapshots, line items, status and actor.
- Dispatch: courier availability, offers, assignments and delivery milestones.
- Tracking: consent records and time-bounded location updates.
- Notifications: event-driven delivery to customer, merchant and courier.
- Administration: staff roles, audit events and operational queries.

These are conceptual boundaries, not an approved physical database schema.

## 4. Data integrity principles
- Store order-line snapshots of product name, quantity, confirmed price and relevant item metadata at order acceptance; later catalog edits must not rewrite past orders.
- Keep catalog reference price separate from branch-confirmed sell price.
- Keep order status history append-only/auditable.
- Use server timestamps and idempotency for order submission and status commands.
- Enforce branch/merchant/courier ownership in backend policies.
- Use transactions for critical operations such as order acceptance and courier assignment.
- Never trust client-calculated totals or authorization claims.

## 5. API and event design
Use explicit commands for lifecycle transitions (submit, accept, reject, start preparation, mark ready, offer courier, accept offer, pickup, start route, deliver, cancel). Each command validates the current state, actor permissions and required fields, then writes an auditable event and emits notifications.

Events should carry stable IDs and timestamps. Notification retries must not create duplicate orders or duplicate state transitions.

## 6. Location privacy
Request location permission only after explaining the purpose. Record consent and its scope. Collect location only while the courier is on duty or handling an active job, according to the approved policy. Android background tracking must comply with platform permission requirements and show a persistent notification. Provide a stop-sharing action and stop collection when the authorized scope ends.

## 7. Environments and release
- Local development.
- Isolated V2 staging.
- Production only after owner approval.
Use separate environment variables/secrets and separate data. CI may build and test feature branches. No automatic production deploys from this branch.

## 8. Technology selection gate
Before committing to a framework, confirm the repository's current contents and CI capabilities. Prefer maintainable, supported Android tooling and a web stack deployable on the chosen host. Do not provision paid services or enable paid fallbacks. Any service with possible charges requires explicit approval.

## 9. Security and observability
- Server-side role/resource authorization.
- Secret scanning and dependency checks.
- Audit sensitive actions.
- Structured logs with personal data minimized/redacted.
- Monitor API errors, order transition failures, notification delivery and queue health.
- Do not log passwords, tokens, full payment details or unnecessary precise location history.

## 10. Open decisions
This architecture does not choose delivery fees, commissions, payment rules, cancellation rules, courier pay, external brand integrations or production hosting. These remain owner decisions.
