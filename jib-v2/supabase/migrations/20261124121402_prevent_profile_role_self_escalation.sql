-- Prevent authenticated users from changing their own authorization role.
-- Profile owners may still edit their public contact/profile fields.
REVOKE UPDATE ON TABLE public.profiles FROM authenticated;
GRANT UPDATE (full_name, phone, avatar_url) ON TABLE public.profiles TO authenticated;
