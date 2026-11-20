import { NextResponse } from "next/server";
import { createClient } from "../../../../../lib/supabase/server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const maxDuration = 30;

const SYSTEM_POLICY = [
  "You are JIB AI Manager, an operations and development assistant for the JIB delivery platform in Rabat.",
  "Follow the approved JIB product decisions. Never propose silently changing approved business rules.",
  "Never claim to have changed code, databases, accounts, billing, orders, prices, or deployments.",
  "Do not request or expose passwords, API keys, access tokens, customer personal data, or precise courier coordinates.",
  "You are advisory only: no tools, SQL, code execution, external actions, or automatic deployments.",
  "Use concise Arabic by default. Distinguish verified facts from assumptions and list required human approvals.",
].join(" ");

function jsonError(error: string, status: number) {
  return NextResponse.json({ error }, { status, headers: { "Cache-Control": "no-store" } });
}

export async function POST(request: Request) {
  const supabase = await createClient();
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return jsonError("يجب تسجيل الدخول أولاً.", 401);

  const { data: profile, error: profileError } = await supabase
    .from("profiles").select("role").eq("id", user.id).maybeSingle();
  if (profileError || profile?.role !== "admin") return jsonError("هذه الخدمة متاحة لمدير JIB فقط.", 403);

  const baseUrl = process.env.FREELLMAPI_BASE_URL?.trim();
  const apiKey = process.env.FREELLMAPI_API_KEY?.trim();
  const model = process.env.FREELLMAPI_FREE_MODEL?.trim();
  if (!baseUrl || !apiKey || !model) {
    return jsonError("مزود FreeLLMAPI غير مهيأ بعد. يلزم عنوان HTTPS ومفتاح خادم ونموذج مجاني موثق؛ لا يوجد تحويل تلقائي إلى نموذج مدفوع.", 503);
  }

  let parsed: unknown;
  try { parsed = await request.json(); } catch { return jsonError("صيغة الطلب غير صالحة.", 400); }
  const prompt = typeof parsed === "object" && parsed !== null && "message" in parsed
    ? (parsed as { message?: unknown }).message
    : null;
  if (typeof prompt !== "string" || !prompt.trim() || prompt.length > 6000) {
    return jsonError("أدخل رسالة من 1 إلى 6000 حرف.", 400);
  }

  let endpoint: URL;
  try {
    endpoint = new URL(baseUrl);
    if (endpoint.protocol !== "https:" && endpoint.hostname !== "localhost" && endpoint.hostname !== "127.0.0.1") {
      return jsonError("يجب أن يستخدم عنوان FreeLLMAPI اتصال HTTPS آمناً.", 400);
    }
  } catch {
    return jsonError("عنوان FreeLLMAPI غير صالح.", 400);
  }

  const normalizedBase = endpoint.toString().replace(/\/$/, "");
  const chatUrl = normalizedBase.endsWith("/v1")
    ? `${normalizedBase}/chat/completions`
    : `${normalizedBase}/v1/chat/completions`;

  try {
    const upstream = await fetch(chatUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: SYSTEM_POLICY },
          { role: "user", content: prompt.trim() },
        ],
        temperature: 0.2,
        max_tokens: 1200,
        stream: false,
      }),
      cache: "no-store",
      signal: AbortSignal.timeout(20_000),
    });
    if (!upstream.ok) {
      const status = upstream.status;
      if (status === 401 || status === 403) return jsonError("رفض مزود FreeLLMAPI بيانات الاعتماد. تحقق من المفتاح دون مشاركته هنا.", 502);
      if (status === 429) return jsonError("انتهت الحصة المجانية أو حد الطلبات. لم يتم تفعيل نموذج مدفوع.", 429);
      return jsonError(`تعذر على FreeLLMAPI إكمال الطلب (HTTP ${status}).`, 502);
    }
    const result = await upstream.json() as {
      choices?: Array<{ message?: { content?: string | Array<{ type?: string; text?: string }> } }>;
      model?: string;
    };
    const content = result.choices?.[0]?.message?.content;
    const answer = typeof content === "string"
      ? content
      : Array.isArray(content)
        ? content.map((part) => part.text ?? "").join("\n")
        : "";
    if (!answer.trim()) return jsonError("أعاد المزود استجابة فارغة أو غير متوافقة.", 502);
    return NextResponse.json({ answer, model: result.model ?? model }, { headers: { "Cache-Control": "no-store" } });
  } catch (error) {
    const message = error instanceof Error && error.name === "TimeoutError"
      ? "انتهت مهلة مزود FreeLLMAPI."
      : "تعذر الاتصال بمزود FreeLLMAPI.";
    return jsonError(message, 503);
  }
}
