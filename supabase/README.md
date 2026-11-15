# Supabase setup for JIB

1. Create a Supabase project in a region suitable for Morocco and keep its database credentials private.
2. Apply migrations in timestamp order from `supabase/migrations/` using the Supabase CLI or SQL editor.
3. Do not enable public signups for merchant, courier or admin roles. New profiles must begin as customers; privileged role assignment is a trusted administrative operation.
4. Configure Auth redirect URLs only for the deployed app domains.
5. Test policies with separate customer, merchant, courier and admin accounts before real data is used.

## Checkout RPC

Call `public.checkout_order(p_store_id, p_address_id, p_items, p_customer_note)` using the authenticated Supabase session. Each item is an object containing only `product_id` and `quantity`. The function reads prices from the database and returns the new order UUID. Never send a client-calculated total as authoritative data.

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

The 15 MAD delivery fee in the migration is a temporary placeholder, not a final pricing policy. Replace it with validated zone/distance pricing before launch.

## Important

Migrations are committed to GitHub but have not been applied to a live Supabase project. No Supabase URL or keys are stored in this repository.
