import { createClient } from "npm:@supabase/supabase-js@2";

type OutboxRow = {
  id: string;
  channel: "email" | "sms" | "whatsapp" | "voice";
  recipient: string | null;
  payload: Record<string, unknown>;
  attempts: number;
};

const OUTBOX = "jib_ai_manager_notification_outbox";
const VOICE_MOROCCO_MOBILE_PER_MINUTE_USD = 1.0748;
const MAX_ATTEMPTS = 5;

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });

function readKeyDictionary(name: string): Record<string, string> {
  const raw = Deno.env.get(name);
  if (!raw) return {};
  try {
    return JSON.parse(raw) as Record<string, string>;
  } catch {
    return {};
  }
}

function xmlEscape(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

function textValue(value: unknown, fallback = ""): string {
  return typeof value === "string" ? value : fallback;
}

function frenchEventSummary(eventType: string, severity: string): string {
  const labels: Record<string, string> = {
    health_check: "un problème technique a été détecté",
    health_check_resolution: "un problème technique a été résolu",
    order_status_changed: "une mise à jour de commande est disponible",
    order_created: "une nouvelle commande a été créée",
    store_changed: "une mise à jour de boutique a été enregistrée",
    product_changed: "une mise à jour de produit a été enregistrée",
    profile_role_change: "un rôle utilisateur a été modifié",
    courier_approval: "un livreur a été approuvé ou mis à jour",
    image_generation_requested: "une demande de création d’image a été reçue",
    image_generation_ready: "une image est prête pour validation",
    image_generation_failed: "la création d’une image a échoué",
    image_generation_reviewed: "une image a été validée ou refusée",
  };
  const urgency = severity === "critical" ? "Urgent" : severity === "warning" ? "Important" : "Information";
  return `${urgency} JIB : ${labels[eventType] ?? "un nouvel événement système est disponible"}. Consultez le tableau de bord pour les détails.`;
}

function buildVoiceTwiML(row: OutboxRow): string {
  const payload = row.payload ?? {};
  const title = textValue(payload.title, "تنبيه من JIB");
  const message = textValue(payload.message, title);
  const eventType = textValue(payload.event_type, "system_update");
  const severity = textValue(payload.severity, "info");
  const languages = Array.isArray(payload.voice_languages)
    ? payload.voice_languages.map((value) => String(value))
    : ["ar", "fr"];

  const segments: string[] = [];
  if (languages.includes("ar")) {
    segments.push(`<Say language="ar-XA">${xmlEscape(`تنبيه من جيب. ${title}. ${message}`)}</Say>`);
  }
  if (languages.includes("fr")) {
    segments.push(`<Say language="fr-FR">${xmlEscape(frenchEventSummary(eventType, severity))}</Say>`);
  }
  if (segments.length === 0) {
    segments.push(`<Say language="ar-XA">${xmlEscape(message)}</Say>`);
  }
  return `<?xml version="1.0" encoding="UTF-8"?><Response>${segments.join("<Pause length=\"1\"/>")}</Response>`;
}

function buildMessage(row: OutboxRow): string {
  const payload = row.payload ?? {};
  const title = textValue(payload.title, "تنبيه من JIB");
  const message = textValue(payload.message, "");
  return [title, message, "لوحة JIB: https://jib-admin-two.vercel.app/monitoring"].filter(Boolean).join("\n").slice(0, 1400);
}

async function resendEmail(row: OutboxRow, apiKey: string, from: string): Promise<string | null> {
  if (!row.recipient) throw new Error("Email recipient is missing");
  const payload = row.payload ?? {};
  const title = textValue(payload.title, "JIB notification");
  const message = textValue(payload.message, "");
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "Idempotency-Key": row.id,
    },
    body: JSON.stringify({
      from,
      to: [row.recipient],
      subject: `[JIB] ${title}`.slice(0, 180),
      text: buildMessage(row),
      html: `<div style="font-family:Arial,sans-serif;direction:rtl;text-align:right"><h2>${title.replaceAll("<", "&lt;").replaceAll(">", "&gt;")}</h2><p>${message.replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll("\n", "<br>")}</p><p><a href="https://jib-admin-two.vercel.app/monitoring">فتح لوحة JIB</a></p></div>`,
    }),
    signal: AbortSignal.timeout(15000),
  });
  const result = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(`Resend ${response.status}: ${textValue(result.message, "email delivery failed")}`);
  return textValue(result.id) || null;
}

async function twilioRequest(
  accountSid: string,
  authToken: string,
  endpoint: "Messages" | "Calls",
  form: URLSearchParams,
): Promise<string | null> {
  const response = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/${endpoint}.json`,
    {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${accountSid}:${authToken}`)}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: form.toString(),
      signal: AbortSignal.timeout(15000),
    },
  );
  const result = await response.json().catch(() => ({}));
  if (!response.ok) {
    const detail = textValue(result.message, textValue(result.code, "Twilio delivery failed"));
    throw new Error(`Twilio ${response.status}: ${detail}`);
  }
  return textValue(result.sid) || null;
}

async function sendTwilioMessage(
  row: OutboxRow,
  accountSid: string,
  authToken: string,
  config: {
    smsFrom?: string;
    messagingServiceSid?: string;
    whatsappFrom?: string;
    whatsappContentSid?: string;
  },
): Promise<string | null> {
  if (!row.recipient) throw new Error("Phone recipient is missing");
  const form = new URLSearchParams();
  form.set("To", row.channel === "whatsapp" ? `whatsapp:${row.recipient}` : row.recipient);

  if (row.channel === "sms") {
    if (config.messagingServiceSid) form.set("MessagingServiceSid", config.messagingServiceSid);
    else if (config.smsFrom) form.set("From", config.smsFrom);
    else throw new Error("Twilio SMS sender is not configured");
    form.set("Body", buildMessage(row));
  } else {
    if (!config.whatsappFrom || !config.whatsappContentSid) {
      throw new Error("Twilio WhatsApp sender and approved template are required");
    }
    form.set("From", config.whatsappFrom);
    form.set("ContentSid", config.whatsappContentSid);
    form.set("ContentVariables", JSON.stringify({
      "1": textValue(row.payload?.title, "JIB notification").slice(0, 120),
      "2": textValue(row.payload?.message, "Consultez le tableau de bord JIB.").slice(0, 900),
    }));
  }

  return await twilioRequest(accountSid, authToken, "Messages", form);
}

async function sendTwilioVoice(
  row: OutboxRow,
  accountSid: string,
  authToken: string,
  voiceFrom: string,
): Promise<string | null> {
  if (!row.recipient) throw new Error("Voice recipient is missing");
  const form = new URLSearchParams();
  form.set("To", row.recipient);
  form.set("From", voiceFrom);
  form.set("Twiml", buildVoiceTwiML(row));
  return await twilioRequest(accountSid, authToken, "Calls", form);
}

async function markFailure(admin: ReturnType<typeof createClient>, row: OutboxRow, error: unknown) {
  const attempts = row.attempts ?? 1;
  const retry = attempts < MAX_ATTEMPTS;
  const delays = [60, 300, 900, 3600, 21600];
  const nextAttempt = retry
    ? new Date(Date.now() + delays[Math.min(attempts - 1, delays.length - 1)] * 1000).toISOString()
    : null;
  const message = (error instanceof Error ? error.message : "Provider delivery failed").slice(0, 500);

  await admin.from(OUTBOX).update({
    status: retry ? "pending" : "failed",
    next_attempt_at: nextAttempt,
    locked_at: null,
    blocked_reason: message,
  }).eq("id", row.id);
}

async function markSent(
  admin: ReturnType<typeof createClient>,
  row: OutboxRow,
  providerMessageId: string | null,
) {
  await admin.from(OUTBOX).update({
    status: "sent",
    provider_message_id: providerMessageId,
    sent_at: new Date().toISOString(),
    next_attempt_at: null,
    locked_at: null,
    blocked_reason: null,
    estimated_cost_usd: row.channel === "voice" ? VOICE_MOROCCO_MOBILE_PER_MINUTE_USD : 0,
  }).eq("id", row.id);
}

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const secretKeys = readKeyDictionary("SUPABASE_SECRET_KEYS");
  const publishableKeys = readKeyDictionary("SUPABASE_PUBLISHABLE_KEYS");
  const serviceKey = secretKeys.default ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const publishableKey = publishableKeys.default ?? Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  if (!supabaseUrl || !serviceKey || !publishableKey) {
    return json({ error: "Supabase server credentials are not configured" }, 503);
  }
  if (request.headers.get("apikey") !== publishableKey) return json({ error: "Unauthorized" }, 401);

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const suppliedSecret = request.headers.get("x-jib-dispatch-secret");
  const { data: expectedSecret, error: secretError } = await admin.rpc("jib_ai_manager_dispatch_secret");
  if (secretError || !expectedSecret || suppliedSecret !== expectedSecret) {
    return json({ error: "Unauthorized" }, 401);
  }

  if (Deno.env.get("JIB_NOTIFICATIONS_ENABLED") !== "true") {
    return json({ ok: true, enabled: false, processed: 0, reason: "owner_activation_required" });
  }

  const resendKey = Deno.env.get("RESEND_API_KEY") ?? "";
  const resendFrom = Deno.env.get("RESEND_FROM_EMAIL") ?? "";
  const twilioSid = Deno.env.get("TWILIO_ACCOUNT_SID") ?? "";
  const twilioToken = Deno.env.get("TWILIO_AUTH_TOKEN") ?? "";
  const smsFrom = Deno.env.get("TWILIO_SMS_FROM") ?? "";
  const messagingServiceSid = Deno.env.get("TWILIO_MESSAGING_SERVICE_SID") ?? "";
  const whatsappFrom = Deno.env.get("TWILIO_WHATSAPP_FROM") ?? "";
  const whatsappContentSid = Deno.env.get("TWILIO_WHATSAPP_CONTENT_SID") ?? "";
  const voiceFrom = Deno.env.get("TWILIO_VOICE_FROM") ?? "";
  const voiceBudget = Number(Deno.env.get("JIB_VOICE_MONTHLY_BUDGET_USD") ?? "0");

  const configured = {
    email: Boolean(resendKey && resendFrom),
    sms: Boolean(twilioSid && twilioToken && (smsFrom || messagingServiceSid)),
    whatsapp: Boolean(twilioSid && twilioToken && whatsappFrom && whatsappContentSid),
    voice: Boolean(twilioSid && twilioToken && voiceFrom && Number.isFinite(voiceBudget) && voiceBudget > 0),
  };

  const allChannels = ["email", "sms", "whatsapp", "voice"] as const;
  for (const channel of allChannels) {
    if (!configured[channel]) {
      await admin.from(OUTBOX).update({
        blocked_reason: channel === "voice" && !(voiceBudget > 0)
          ? "voice_budget_not_approved"
          : "provider_not_configured",
      }).eq("channel", channel).eq("status", "awaiting_provider");
    }
  }

  let voiceLimit = 0;
  if (configured.voice) {
    const monthStart = new Date(Date.UTC(new Date().getUTCFullYear(), new Date().getUTCMonth(), 1)).toISOString();
    const { count } = await admin.from(OUTBOX)
      .select("id", { count: "exact", head: true })
      .eq("channel", "voice")
      .eq("status", "sent")
      .gte("created_at", monthStart);
    const estimatedSpent = (count ?? 0) * VOICE_MOROCCO_MOBILE_PER_MINUTE_USD;
    voiceLimit = Math.min(2, Math.max(0, Math.floor((voiceBudget - estimatedSpent) / VOICE_MOROCCO_MOBILE_PER_MINUTE_USD)));
    if (voiceLimit === 0) {
      await admin.from(OUTBOX).update({ blocked_reason: "voice_monthly_budget_reached" })
        .eq("channel", "voice").eq("status", "awaiting_provider");
    }
  }

  const limits: Array<{ channel: OutboxRow["channel"]; limit: number }> = [];
  if (configured.email) limits.push({ channel: "email", limit: 20 });
  if (configured.sms) limits.push({ channel: "sms", limit: 20 });
  if (configured.whatsapp) limits.push({ channel: "whatsapp", limit: 20 });
  if (configured.voice && voiceLimit > 0) limits.push({ channel: "voice", limit: voiceLimit });

  if (limits.length === 0) {
    return json({ ok: true, enabled: true, processed: 0, configured, reason: "providers_not_ready_or_voice_budget_missing" });
  }

  let processed = 0;
  const failures: Array<{ id: string; channel: string; error: string }> = [];

  for (const item of limits) {
    const { data, error } = await admin.rpc("jib_ai_manager_claim_notifications", {
      p_channels: [item.channel],
      p_limit: item.limit,
    });
    if (error) {
      failures.push({ id: "claim", channel: item.channel, error: error.message });
      continue;
    }

    const rows = (data ?? []) as OutboxRow[];
    for (const row of rows) {
      try {
        let providerId: string | null = null;
        if (row.channel === "email") {
          providerId = await resendEmail(row, resendKey, resendFrom);
        } else if (row.channel === "sms" || row.channel === "whatsapp") {
          providerId = await sendTwilioMessage(row, twilioSid, twilioToken, {
            smsFrom,
            messagingServiceSid,
            whatsappFrom,
            whatsappContentSid,
          });
        } else {
          providerId = await sendTwilioVoice(row, twilioSid, twilioToken, voiceFrom);
        }
        await markSent(admin, row, providerId);
        processed += 1;
      } catch (error) {
        await markFailure(admin, row, error);
        failures.push({
          id: row.id,
          channel: row.channel,
          error: (error instanceof Error ? error.message : "Delivery failed").slice(0, 250),
        });
      }
    }
  }

  return json({ ok: true, enabled: true, processed, configured, failures });
});
