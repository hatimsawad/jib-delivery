# JIB Courier App

Flutter app for JIB couriers.

- Email/password account registration and sign-in through Supabase Auth.
- New courier accounts remain pending until approved by an administrator.
- Pending couriers cannot see customer delivery addresses or claim deliveries.
- Approved couriers can view available orders, claim one atomically, mark pickup, start delivery, and confirm completion.
- Server-side RPC functions enforce approval, assignment ownership, and valid status transitions.

The app uses the JIB Supabase project URL and public publishable key. Never put a Supabase service-role or secret key in a mobile application.
