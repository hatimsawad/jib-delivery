import { createClient } from "npm:@supabase/supabase-js@2";

type CheckResult = { count: number | null; error: string | null };

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

async function countRows(
  admin: ReturnType<typeof createClient>,
  table: string,
  filters: (query: any) => any = (query) => query,
): Promise<CheckResult> {
  try {
    let query = admin.from(table).select("id", { count: "exact", head: true });
    query = filters(query);
    const { count, error } = await query;
    return { count: count ?? 0, error: error?.message ?? null };
  } catch (error) {
    return { count: null, error: error instanceof Error ? error.message : "Unknown query error" };
  }
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

  if (request.headers.get("apikey") !== publishableKey) {
    return json({ error: "Unauthorized" }, 401);
  }

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const suppliedSecret = request.headers.get("x-jib-monitor-secret");
  const { data: expectedSecret, error: secretError } = await admin.rpc("jib_ai_manager_monitor_secret");

  if (secretError || !expectedSecret || suppliedSecret !== expectedSecret) {
    return json({ error: "Unauthorized" }, 401);
  }

  const startedAt = Date.now();
  const issues: string[] = [];
  let websiteStatus: number | null = null;

  try {
    const response = await fetch("https://jib-admin-two.vercel.app/login", {
      method: "GET",
      redirect: "follow",
      signal: AbortSignal.timeout(12000),
    });
    websiteStatus = response.status;
    if (!response.ok) issues.push(`manager_web_http_${response.status}`);
  } catch {
    issues.push("manager_web_unreachable");
  }

  const [orders, stores, products, couriers, settings] = await Promise.all([
    countRows(admin, "orders"),
    countRows(admin, "stores", (query) => query.eq("is_active", true)),
    countRows(admin, "products"),
    countRows(admin, "courier_profiles", (query) => query.eq("is_active", true)),
    admin.from("jib_ai_manager_settings")
      .select("id,notification_channels,notification_call_mode,notification_voice_languages")
      .eq("id", 1)
      .maybeSingle(),
    admin.storage.getBucket("product-images"),
  ]);

  const checks: Record<string, CheckResult> = { orders, stores, products, couriers };
  for (const [name, result] of Object.entries(checks)) {
    if (result.error) issues.push(`database_${name}_query_failed`);
  }
  if (settings.error || !settings.data) issues.push("manager_settings_unavailable");
  if (bucket.error || !bucket.data) issues.push("storage_product_images_bucket_unavailable");
  const expectedChannels = ["email", "sms", "whatsapp", "voice"];
  if (settings.data && expectedChannels.some((channel) => !settings.data.notification_channels.includes(channel))) {
    issues.push("notification_channels_incomplete");
  }

  const databaseDown = Object.values(checks).some((result) => result.error) || Boolean(settings.error);
  const status = databaseDown ? "down" : issues.length > 0 ? "degraded" : "healthy";
  const metrics = {
    orders: orders.count,
    active_stores: stores.count,
    products: products.count,
    active_couriers: couriers.count,
    notification_channels: settings.data?.notification_channels ?? [],
    call_mode: settings.data?.notification_call_mode ?? null,
    voice_languages: settings.data?.notification_voice_languages ?? [],
    product_image_bucket_available: Boolean(bucket.data) && !bucket.error,
    provider_delivery_configured: false,
  };
  const durationMs = Date.now() - startedAt;

  const { error: historyError } = await admin.from("jib_ai_manager_health_checks").insert({
    status,
    website_status: websiteStatus,
    duration_ms: durationMs,
    metrics,
    issues,
  });

  if (historyError) return json({ error: "Could not persist health result" }, 500);

  if (issues.length > 0) {
    for (const issue of issues) {
      const fingerprint = `health:${issue}`;
      const { data: existing } = await admin
        .from("jib_ai_manager_events")
        .select("id,occurrence_count")
        .eq("fingerprint", fingerprint)
        .eq("status", "open")
        .maybeSingle();

      if (existing) {
        await admin.from("jib_ai_manager_events").update({
          last_seen_at: new Date().toISOString(),
          occurrence_count: existing.occurrence_count + 1,
          details: { website_status: websiteStatus, metrics },
        }).eq("id", existing.id);
      } else {
        await admin.from("jib_ai_manager_events").insert({
          fingerprint,
          event_type: "health_check",
          severity: databaseDown ? "critical" : "warning",
          title: "JIB system health issue",
          message: issue,
          details: { website_status: websiteStatus, metrics },
          status: "open",
        });
      }
    }
  } else {
    await admin.from("jib_ai_manager_events").update({
      status: "resolved",
      resolved_at: new Date().toISOString(),
      last_seen_at: new Date().toISOString(),
    }).eq("event_type", "health_check").eq("status", "open");
  }

  return json({
    ok: true,
    status,
    website_status: websiteStatus,
    duration_ms: durationMs,
    metrics,
    issues,
  });
});
