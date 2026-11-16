-- Enforce store approval and courier approval at the database privilege layer.
-- Store creation and activation must happen only through validated SECURITY DEFINER RPCs.
revoke all privileges on table public.stores from anon, authenticated;
revoke insert (
  id, owner_id, name, description, category, phone, address_text,
  latitude, longitude, is_active, is_open, created_at, updated_at
) on table public.stores from authenticated;
revoke update (
  id, owner_id, name, description, category, phone, address_text,
  latitude, longitude, is_active, is_open, created_at, updated_at
) on table public.stores from authenticated;
revoke references (
  id, owner_id, name, description, category, phone, address_text,
  latitude, longitude, is_active, is_open, created_at, updated_at
) on table public.stores from authenticated;

grant select on table public.stores to authenticated;
grant update (
  name, description, phone, address_text, latitude, longitude, is_open
) on table public.stores to authenticated;

-- Courier status/approval is controlled only by register/admin RPCs.
revoke all privileges on table public.courier_profiles from anon, authenticated;
revoke insert (
  user_id, phone, is_active, created_at, approved_at, approved_by
) on table public.courier_profiles from authenticated;
revoke update (
  user_id, phone, is_active, created_at, approved_at, approved_by
) on table public.courier_profiles from authenticated;
revoke references (
  user_id, phone, is_active, created_at, approved_at, approved_by
) on table public.courier_profiles from authenticated;

grant select on table public.courier_profiles to authenticated;

drop policy if exists courier_profiles_read_own on public.courier_profiles;
drop policy if exists courier_profiles_admin_read on public.courier_profiles;
create policy courier_profiles_read_own_or_admin
  on public.courier_profiles for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or (select public.is_jib_admin())
  );

create index if not exists courier_profiles_approved_by_idx
  on public.courier_profiles(approved_by);
