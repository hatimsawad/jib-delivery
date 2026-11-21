# JIB V2 — Product Requirements

Status: Working specification for implementation in `jib-v2-bootstrap`.
Scope: New JIB V2 only. The legacy project and BLACKNESS data are protected.

## 1. Product
JIB is a multi-sided delivery platform initially serving Rabat/Temara, Morocco. It coordinates customers, merchants/branches, couriers and JIB operations through one shared backend.

## 2. Deliverables
1. Customer Android application.
2. Merchant Android application.
3. Courier Android application.
4. Private responsive web administration dashboard.

The dashboard is a private web application accessed in a browser by authorized JIB staff. It is not a public Google page and does not require a separate consumer app.

## 3. Customer experience
- Browse approved brands and their branches.
- Browse products and display prices where reliable catalog data exists.
- Clearly distinguish reference/catalog prices from branch-confirmed price, stock and orderability.
- Show availability only when confirmed for the selected branch; otherwise label it as unconfirmed/unavailable and do not imply that a reference listing can be purchased.
- Build and submit an order with delivery address and contact details.
- Track order status, elapsed time and estimated remaining time.
- Receive status updates and delivery progress.
- View order history and support/contact information.

## 4. Merchant experience
- Secure merchant/branch sign-in and branch-scoped access.
- Receive new orders and accept or reject them with a reason.
- Confirm item availability and any price discrepancy before acceptance/final confirmation.
- Mark preparation started and completed; record relevant timestamps.
- Mark order ready for courier pickup and confirm handoff.
- View current and historical orders.
- Never expose another merchant's orders or customer data.

## 5. Courier experience
- Secure courier sign-in.
- Set availability/on-duty state.
- Receive delivery offers and accept/decline them.
- View pickup and delivery details only for assigned work.
- Record arrival, pickup, en-route and delivered milestones.
- Provide proof of delivery using a method approved for implementation.
- Background location sharing is opt-in, purpose-limited and tied to the approved work state/active delivery. Explain purpose before requesting permission; use required Android permissions and a persistent notification while tracking; provide a clear stop control. No covert tracking.

## 6. End-to-end order lifecycle
The lifecycle must be explicit and auditable:
- customer_submitted
- merchant_accepted OR merchant_rejected
- preparing
- ready_for_pickup
- courier_offered
- courier_accepted
- picked_up
- en_route
- delivered
- cancelled (with actor, reason and timestamp)

Do not silently skip or permit invalid transitions. The exact policy for cancellation, reassignment, payment, refunds and failed delivery must be specified before implementation if it affects money or customer commitments.

## 7. Time and tracking
Record server-side timestamps for submission, merchant response, preparation start/completion, courier offer/acceptance, pickup, en-route and delivery. Display elapsed time and estimated remaining time. ETA is an estimate, not a guarantee; record the estimate and its update time. Admin and merchant operational views must show relevant milestone history.

## 8. Administration
Private role-protected dashboard for authorized JIB staff:
- Overview of orders and lifecycle status.
- Search/filter orders and inspect their event timeline.
- Manage/verify merchants, branches, brands, catalog entries and couriers subject to role permissions.
- Review availability and catalog/branch price discrepancies.
- Operational visibility into delayed, unassigned and exception orders.
- Audit log for sensitive administrative changes.
No public access to operational/customer data.

## 9. Catalog and brand rules
- Brand directory is managed/approved by JIB.
- Brand/product reference data and branch-specific sellable inventory are separate concepts.
- A product template/reference price is not proof of stock, current price or ability to order.
- Branch-specific availability and price require confirmation.
- Do not invent brand integrations or assume every brand has an external partner app.
- Preserve source/provenance for catalog prices where available.

## 10. Shared platform and security
- All four clients use one coherent backend identity, authorization and order model.
- Enforce role- and resource-scoped authorization on the server, not only in UI.
- Validate all order and status transitions server-side.
- Keep secrets out of client apps and source control.
- Use TLS, secure session handling, audit events and least-privilege access.
- Protect customer personal data and courier location data.
- Define retention and deletion rules before production launch.

## 11. Non-goals / unresolved decisions
Do not invent or silently decide:
- Delivery fee, merchant commission, courier compensation or any percentage/flat-fee formula.
- Payment provider, cash/card policy, refunds or settlement.
- Cancellation penalties, service-level guarantees or dispute policy.
- Exact courier assignment algorithm and geographic coverage boundaries.
- Proof-of-delivery method and identity verification policy.
These require owner approval before implementation.

## 12. Protected legacy boundary
- Do not modify the legacy production app, its database, BLACKNESS account or historical data.
- Do not run migrations or data imports against the legacy Supabase project.
- Any future integration/migration requires a separate written plan, backup/rollback plan and explicit owner approval.
- Work in this branch is development documentation/source only until reviewed.

## 13. Release gates
No deliverable is called final until it builds, installs on a real Android device (where applicable), connects to a staging backend, and passes the agreed end-to-end tests. Production release requires owner approval.
