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


## AI image generation

- Provider: Vercel AI Gateway, using the existing `jib-admin` Vercel project identity (OIDC) where available; no separate Black Forest Labs account is required.
- Model: `bfl/flux-3-image-klein`.
- Reference model price: USD 0.009 per generated image. Vercel currently advertises USD 5 of credits every 30 days for eligible free users; eligibility/billing settings must be confirmed in the Vercel account.
- Safety cap in the database: 100 image requests per calendar month (reference spend USD 0.90 at the listed per-image price). Failed attempts also count toward the cap.
- Product images are uploaded to `product-images` under the store's folder. Article covers use the admin-only `article-images` bucket.
- All generated images are drafts. The merchant or admin must approve before a product's `image_url` is changed. AI-generated imagery must be labeled as such.
- The first real image-generation request must be tested on the production Vercel domain after deployment. If OIDC authentication is unavailable, configure `AI_GATEWAY_API_KEY` as a Vercel server-side environment secret; never expose it to the mobile apps.


## Notification dispatcher activation

The Supabase Edge Function `jib-ai-manager-dispatch` is deployed and scheduled once per minute. It deliberately sends nothing unless `JIB_NOTIFICATIONS_ENABLED=true` and the relevant provider secrets exist. Provider credentials belong only in **Supabase Dashboard → Edge Functions → Secrets**; never commit them to GitHub or put them in Android apps.

Required server-side secrets:

- Email: `RESEND_API_KEY`, `RESEND_FROM_EMAIL` (the sender address must belong to a verified domain).
- Twilio base: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`.
- SMS: either `TWILIO_MESSAGING_SERVICE_SID` or `TWILIO_SMS_FROM` (use a sender approved for Morocco).
- WhatsApp: `TWILIO_WHATSAPP_FROM`, `TWILIO_WHATSAPP_CONTENT_SID` (approved template with variables 1=title and 2=message).
- Voice: `TWILIO_VOICE_FROM`, plus `JIB_VOICE_MONTHLY_BUDGET_USD`. Voice stays blocked if the budget is missing or zero.
- Final activation switch: `JIB_NOTIFICATIONS_ENABLED=true`.

Voice calls use Arabic (`ar-XA`) and French (`fr-FR`) speech. The dispatcher reserves USD 1.50 per Moroccan mobile call as a conservative one-minute allowance including a TTS buffer; actual provider charges can vary. Twilio's published mobile-call rate is a base rate and does not guarantee the total voice/TTS cost. Do not set a budget until the owner explicitly approves the spend.

The dispatcher claims jobs with row locks, retries transient failures with backoff, recovers stale processing locks, and leaves unconfigured channels in `awaiting_provider`. WhatsApp production alerts require an approved template; Morocco SMS sender registration may take several weeks.
