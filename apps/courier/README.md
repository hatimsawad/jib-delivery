# JIB Courier App

Flutter app for JIB couriers.

## Core operations

- Email/password account registration and sign-in through Supabase Auth.
- New courier accounts remain pending until approved by an administrator.
- Pending couriers cannot see customer delivery addresses or claim deliveries.
- Approved couriers can view available orders, claim one atomically, mark pickup, start delivery, and confirm completion.
- Server-side RPC functions enforce approval, assignment ownership, and valid status transitions.
- Order timeline shows completed milestones, elapsed time, and expected remaining time.

## Consent-based location sharing

- Location sharing is OFF until the courier explicitly accepts the in-app disclosure and grants Android location permission.
- The disclosure explains purpose, login/work relationship, background operation, persistent notification, 90-day retention, and how to stop sharing.
- Android uses Geolocator's location foreground service with an ongoing notification. The service must be started while the app is visible; Android may restrict operation after force-stop, permission revocation, battery restrictions, or OEM process management.
- The Android APK workflow adds location and foreground-service permissions to the courier app only. Customer and merchant APKs receive only the Internet permission.
- The courier can stop sharing in the app; logout also stops sharing and revokes the server-side consent state.
- The app sends coordinates through authenticated `record_courier_location` RPC. Direct table writes are revoked; location tables are admin-read-only under RLS.
- Only approved active couriers with enabled consent can submit coordinates or be auto-assigned.
- Supabase cron checks stale location heartbeats every minute and creates a JIB Manager incident when the last update is older than 60 seconds. This is a scheduled check, so alert visibility may lag the threshold by up to one cron interval.
- Location history is pruned daily after 90 days.
- Automatic assignment selects the nearest approved, consenting courier with a fresh location and no active delivery; if none is available, it records a pending-assignment incident for retry.

## Release validation still required

- Install the release APK on physical Android devices across supported Android versions.
- Verify foreground notification, background updates after screen lock/app backgrounding, stop-sharing, logout, permission revocation, GPS disabled, network loss/recovery, and force-stop behavior.
- Verify that location events stop after consent is revoked and are not accessible to customers, merchants, or couriers through direct Data API access.
- Verify 60-second stale alert behavior and 90-day scheduled deletion in a controlled test environment.

The app uses the JIB Supabase project URL and public publishable key. Never put a Supabase service-role or secret key in a mobile application.
