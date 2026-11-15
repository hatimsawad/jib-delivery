# JIB security review — initial pass

## Fixed in migration 202611150002

- Removed customer direct-insert policies for orders and order items.
- Revoked client-side writes to orders, order items and order events. This prevents a client from submitting arbitrary totals or changing delivery/payment states.

## Required before any real orders

1. Implement a trusted checkout RPC or Edge Function. It must derive the customer from the authenticated session, validate an active/open store and available products, fetch authoritative prices, validate quantities and address ownership, calculate fees/totals, and create the order, items and initial event atomically.
2. Add role-aware authorization for merchant and courier status transitions. Never accept a role, courier assignment, payment state or order total from an untrusted client.
3. Restrict profile role changes; users must not be able to promote themselves to merchant, courier or admin.
4. Add store-owner-only update policies and explicit admin authorization, then test every policy with multiple users.
5. Add rate limits, input validation, audit logging and secret management before public launch.

## Status

This is a security hardening step, not a complete security certification. No live Supabase project has been connected and migrations have not been applied to production.
