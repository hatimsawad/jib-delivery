-- Remove broad default client privileges. RLS does not protect against TRUNCATE,
-- and profile role changes must never be available to ordinary users.
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM anon, authenticated;

-- Signed-in users can read rows allowed by the existing RLS policies.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;

-- Merchants manage only stores/products allowed by owner-scoped RLS policies.
GRANT INSERT, UPDATE, DELETE ON TABLE public.stores, public.products TO authenticated;

-- Customers manage their own addresses under addresses_owner_manage.
GRANT INSERT, UPDATE, DELETE ON TABLE public.addresses TO authenticated;

-- Users may edit personal profile fields only. Role and identity fields are server-managed.
GRANT UPDATE (full_name, phone, preferred_language) ON TABLE public.profiles TO authenticated;

-- Profiles are provisioned by the auth.users trigger, not by client-side inserts.
DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
