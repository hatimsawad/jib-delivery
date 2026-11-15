# JIB admin account setup

This procedure is for the project owner during initial Supabase setup. Do not expose the database owner or service-role credentials to the browser or commit them to GitHub.

## 1. Configure the dashboard

Copy `apps/admin/.env.example` to `.env.local` and set:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

The dashboard uses Supabase Auth for sign-in and checks `profiles.role = 'admin'` on the server for every dashboard request.

## 2. Create the first administrator

1. Apply all migrations in timestamp order.
2. In Supabase Authentication, create the intended administrator account with a verified email and a strong unique password. Do not enable open public admin registration.
3. The migration `202611150005_create_profiles_for_auth_users.sql` creates a customer profile automatically for every new Auth user.
4. In the Supabase SQL Editor, identify the account:

```sql
select id, email from auth.users where email = 'YOUR_ADMIN_EMAIL';
```

5. Promote only that exact user. The role guard deliberately blocks ordinary authenticated role changes; as project owner, temporarily disable its trigger in the SQL Editor, update the one matching profile, then immediately re-enable the trigger:

```sql
begin;
alter table public.profiles disable trigger profiles_guard_role;
update public.profiles
set role = 'admin', updated_at = now()
where id = 'PASTE_THE_AUTH_USER_UUID_HERE';
alter table public.profiles enable trigger profiles_guard_role;
commit;
```

6. Confirm exactly one intended account has the admin role:

```sql
select u.email, p.role
from auth.users u join public.profiles p on p.id = u.id
where p.role = 'admin';
```

Use a separate everyday customer account for customer-app testing. Keep administrator credentials private and enable MFA where available.

## 3. Local dashboard

```bash
cd apps/admin
npm install
npm run dev
``

Open `http://localhost:3000/login`.

## Security note

The admin dashboard is not ready for public deployment until the migrations have been applied and tested, an administrator account has been provisioned, environment variables have been configured in the hosting provider, and authorization has been reviewed end-to-end. The service-role key is not required by the current dashboard and must never be exposed client-side.
