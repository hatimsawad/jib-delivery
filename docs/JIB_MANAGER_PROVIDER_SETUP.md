# JIB AI Manager provider onboarding

The notification destinations and preferred channels are already stored in the JIB database. Delivery is intentionally disabled until the owner creates and verifies provider accounts and approves any paid usage.

## Recommended providers

### Email — Resend
- Free tier currently lists 3,000 emails/month and 100 emails/day.
- Verify a sender domain before using a JIB-branded sender address.
- Create an API key and store it as an Edge Function secret named `RESEND_API_KEY`.
- Store the verified sender address as `RESEND_FROM_EMAIL`.

### SMS, WhatsApp and voice — Twilio
- Twilio offers a free trial for initial testing; production sending/calling is usage-based and may require account upgrade.
- Morocco SMS is one-way only. Twilio recommends a pre-registered alphanumeric sender ID; registration is required and the stated provisioning time is about three weeks. International numeric sender IDs may be overwritten by carriers, and delivery is best-effort.
- For outbound voice, enable Morocco in Voice Geo Permissions and confirm that the account is authorized to dial the destination.
- WhatsApp requires explicit recipient opt-in. Business-initiated notifications need approved templates and a registered WhatsApp sender/WABA.
- Store credentials only as Edge Function secrets: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_MESSAGING_SERVICE_SID`, `TWILIO_WHATSAPP_FROM`, `TWILIO_VOICE_FROM`, and the approved WhatsApp content/template ID.

## Safe activation sequence

1. Create the provider accounts using the owner's own email and phone, complete any identity/phone verification, and review the billing terms.
2. Verify the JIB email sender domain in Resend.
3. Register the Morocco SMS sender ID in Twilio and wait for approval.
4. Register a WhatsApp sender and submit the transactional notification templates for approval.
5. Enable and test outbound voice calls to Morocco in Twilio Geo Permissions.
6. Add the provider credentials as Supabase Edge Function secrets. Never paste them into GitHub, app source code, or this chat.
7. Run one test per channel only after the owner explicitly approves the test and any associated charge.
8. Enable the notification worker with idempotency, retries, a spend cap and a delivery log.

## Current state

- Email/SMS/WhatsApp/voice preferences: saved.
- Scheduled JIB website/database health monitoring: active every five minutes.
- Every new manager incident/activity is placed into a private, idempotent four-channel outbox. Jobs remain `awaiting_provider` and are not sent until credentials are configured and the owner approves activation.
- Provider delivery: not configured; no paid messages or calls are sent.
- AI image generation and AI code repair: not connected to an application model provider yet.
