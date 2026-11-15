# Supabase for JIB

## Connected project

- Project name: JIB
- Project ref: emvleaghjsmzjmzgguvu
- Region: eu-west-3 (Paris)
- The project was created on the free plan with a $0/month creation quote. Free-plan limits and any future paid usage still apply.

## Database status

The six SQL migrations in `supabase/migrations/` have been applied successfully to the live JIB project. They create the initial marketplace schema, RLS policies, trusted checkout RPC, role guard, admin read policies, auth profile trigger and additional function grants/indexes.

Seven application tables have RLS enabled: profiles, stores, products, addresses, orders, order_items and order_events.

## Checkout RPC

Call `public.checkout_order(p_store_id, p_address_id, p_items, p_customer_note)` using the authenticated Supabase session. Each item contains only `product_id` and `quantity`. The function reads prices from the database and returns the new order UUID. Never send a client-calculated total as authoritative data.

Example payload:

```json
{
  "p_store_id": "STORE_UUID",
  "p_address_id": "ADDRESS_UUID",
  "p_items": [
    { "product_id": "PRODUCT_UUID", "quantity": 2 }
  ],
  "p_customer_note": "بدون بصل"
}
```

The 15 MAD delivery fee is temporary and must be replaced with validated zone/distance pricing before launch.

## Security notes

- New Auth users receive a customer profile automatically.
- Trigger-only privileged functions cannot be called directly through the Data API.
- Checkout is an authenticated SECURITY DEFINER RPC with an explicit auth.uid() check; it remains subject to further security testing.
- Do not expose a service-role/secret key in mobile or browser applications.
- The first admin has not yet been provisioned.
- Test with separate customer, merchant, courier and admin accounts before public use.
