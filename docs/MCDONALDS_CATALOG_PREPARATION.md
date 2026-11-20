# McDonald's Morocco — JIB pre-launch catalogue preparation

Updated: 2026-11-20

## What is prepared

- The existing commercial brand directory contains 51 brands. McDonald's is already present and its brand-directory status is `approved`.
- A separate `commercial_brand_product_templates` table was created with admin-only RLS.
- 157 McDonald's Morocco product-name templates were imported from the official McDonald's Morocco sitemap/menu catalogue:
  https://www.mcdonalds.ma/new/plan-du-site
- All 157 templates are `draft`, `is_active = false`, and `price_mad = null`.
- The templates are not connected to a store branch and cannot appear in customer discovery or checkout.

## Approval and activation boundary

The owner reports having obtained a manager's approval. This has been taken into account for preparation, but it is not treated as permission to activate an arbitrary branch or to claim a direct-ordering/API/POS arrangement. Before activation, record the approved branch/address, scope of permission, permitted order channel, current local menu, item availability, prices, and any restrictions. If the manager's approval is branch-specific, apply it only to that branch.

## Real operating inventory at audit time

- One real store row exists in Supabase and remains onboarding-pending.
- One live product exists, attached to that pending store.
- No McDonald's branch row or live McDonald's product has been created.
- Do not activate the existing pending store or create a fictional McDonald's branch.

## Next steps

1. Register each real McDonald's Rabat branch with its verified address and contact details.
2. Attach the manager approval reference to the specific branch and order channel.
3. Confirm the official local menu against the actual branch menu.
4. Enter verified branch prices, options/modifiers, images and availability.
5. Review each draft template and only then mark it ready for approval.
6. Activate the branch and products only after owner approval and required partner/branch documentation are recorded.

The official public catalogue can change. Product names are preparation references only, not a guarantee of local stock, price, or current availability.
