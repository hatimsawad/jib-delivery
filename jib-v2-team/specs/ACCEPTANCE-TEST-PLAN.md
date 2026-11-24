# JIB V2 — Acceptance Test Plan

Status: Required release checklist. Tests are not yet executed.
Target: isolated V2 staging environment and physical Android devices.

## 1. Build and install
- [ ] Customer Android app builds from a clean checkout.
- [ ] Merchant Android app builds from a clean checkout.
- [ ] Courier Android app builds from a clean checkout.
- [ ] Each APK installs and launches on a supported physical Android phone.
- [ ] Admin web app loads at its staging URL and is not publicly accessible without authorization.
- [ ] No client contains backend service-role keys or other privileged secrets.

## 2. Identity and access
- [ ] Customer can sign in and access only their own profile/orders.
- [ ] Merchant user can access only authorized merchant/branch orders.
- [ ] Courier can access only assigned/accepted delivery information.
- [ ] Admin permissions are role-scoped.
- [ ] Unauthorized API requests fail even if sent outside the UI.

## 3. Catalog and branch availability
- [ ] Approved brand list loads reliably.
- [ ] Product names/images/reference prices render when data exists.
- [ ] Missing price/source is handled without fabricated values.
- [ ] Reference price is visibly distinguished from confirmed branch price.
- [ ] Out-of-stock or unconfirmed items cannot be submitted as confirmed available.
- [ ] Branch-specific price/availability changes are reflected without corrupting historical orders.

## 4. Order lifecycle
- [ ] Customer submits a valid order once; retries do not create duplicates.
- [ ] Merchant receives the order and can accept/reject with required reason.
- [ ] Merchant preparation milestones are recorded.
- [ ] Courier offer/acceptance and assignment are recorded.
- [ ] Pickup, en-route and delivery transitions are validated.
- [ ] Invalid or out-of-order transitions are rejected.
- [ ] Each milestone has a server timestamp and actor.
- [ ] Customer sees current status, elapsed time and ETA with last-updated time.
- [ ] Merchant/admin can inspect the full timeline.
- [ ] Cancellation and exception flows are tested after their policies are approved.

## 5. Courier location
- [ ] Permission is requested only after a clear explanation.
- [ ] Declining permission does not silently block unrelated app functionality.
- [ ] Background tracking operates only in the approved work scope.
- [ ] Persistent notification is visible while background tracking is active.
- [ ] Courier can stop sharing and tracking stops when the authorized scope ends.
- [ ] Location is not exposed to unrelated merchants/customers.
- [ ] No tracking occurs without valid consent and required permission.

## 6. Notifications and reliability
- [ ] Customer, merchant and courier receive the correct lifecycle notifications.
- [ ] Retries do not duplicate state changes or notifications in a harmful way.
- [ ] Offline/reconnect behavior does not lose confirmed server state.
- [ ] Loading, empty, error and permission-denied states are usable and understandable.

## 7. Data isolation and regression
- [ ] V2 staging uses a dedicated backend project and credentials.
- [ ] Automated tests and migrations target only V2 staging.
- [ ] Legacy JIB and BLACKNESS records are unchanged.
- [ ] No test uses real customer/courier personal data without authorization.
- [ ] Backup/rollback plan exists before any future production change.

## 8. Owner sign-off
- [ ] Unresolved commercial policies are approved before they are implemented.
- [ ] All critical and high-severity defects are closed.
- [ ] End-to-end test evidence is attached.
- [ ] Owner explicitly approves production release.

A checkbox may be marked complete only when supported by recorded test evidence. This document is a plan, not evidence that tests have passed.
