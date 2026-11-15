# JIB Admin Dashboard

Arabic-first Next.js dashboard scaffold for operations in Rabat.

## Run locally

Requirements: Node.js 20.9+ and npm.

```bash
cd apps/admin
npm install
npm run dev
```

Open http://localhost:3000. The current page is a visual scaffold with placeholder metrics; it does not yet connect to live orders or Supabase.

## Next integration steps

- Add Supabase server/client configuration using environment variables.
- Implement authenticated admin sessions and server-verified admin authorization.
- Add protected pages for orders, stores, couriers and reporting.
- Never expose the Supabase service-role key in browser code.
