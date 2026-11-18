import { Buffer } from "node:buffer";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "../../../../types/database.types";
import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const maxDuration = 60;
export const dynamic = "force-dynamic";

const IMAGE_MODEL = "cloudflare/@cf/black-forest-labs/flux-1-schnell";
const CLOUDFLARE_MODEL = "@cf/black-forest-labs/flux-1-schnell";
const ESTIMATED_COST_USD = 0.0005;
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

type ReservedImageJob = {
  job_id: string;
  store_id: string | null;
  title: string;
  description: string;
};

type ImageJobRpcClient = {
  rpc(
    functionName: string,
    args: Record<string, unknown>,
  ): Promise<{ data: unknown; error: { message: string } | null }>;
};

type ImageRequest = {
  type?: "product" | "article";
  productId?: string;
  title?: string;
  description?: string;
};

type CloudflareImageResponse = {
  success?: boolean;
  errors?: Array<{ message?: string }>;
  result?: { image?: string };
};

function jsonError(message: string, status: number) {
  return NextResponse.json({ error: message }, { status });
}

function buildPrompt(type: "product" | "article", title: string, description: string) {
  const prompt = type === "product"
    ? [
        "Create one premium, photorealistic food photograph for a Moroccan food-delivery marketplace.",
        `Dish name: ${title}.`,
        `Ingredients and restaurant description: ${description}.`,
        "Ingredient fidelity is essential: depict only the ingredients and preparation details supplied. Do not invent meat, seafood, dairy, nuts, sauces, toppings, or allergens that are not mentioned.",
        "Show the finished dish as it would actually be served, appetizing but realistic, with natural textures, accurate proportions, soft studio daylight, and a clean neutral tabletop.",
        "Single dish, centered composition, square 1:1 framing, high-end commercial restaurant photography.",
        "No text, no typography, no menu labels, no logos, no watermarks, no packaging, no people, no extra dishes.",
      ].join(" ")
    : [
        "Create one premium editorial cover image for a JIB article.",
        `Article title: ${title}.`,
        `Article summary and context: ${description}.`,
        "Create a clear visual metaphor for the article's central idea, with a refined modern Moroccan editorial feel, strong subject hierarchy, natural lighting, and polished composition.",
        "Compose the subject centrally so the square image can be safely cropped for article cards.",
        "No text, no typography, no logos, no watermarks, no fabricated charts or labels.",
      ].join(" ");

  // Cloudflare FLUX.1 Schnell accepts prompts up to 2,048 characters.
  return prompt.slice(0, 2048);
}

async function generateWithCloudflare(prompt: string): Promise<Uint8Array> {
  const accountId = process.env.CLOUDFLARE_ACCOUNT_ID?.trim();
  const apiToken = process.env.CLOUDFLARE_API_TOKEN?.trim();
  if (!accountId || !apiToken) {
    throw new Error("CLOUDFLARE_NOT_CONFIGURED");
  }

  const response = await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${accountId}/ai/run/${CLOUDFLARE_MODEL}`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ prompt, steps: 4 }),
      signal: AbortSignal.timeout(50_000),
      cache: "no-store",
    },
  );

  const payload = (await response.json().catch(() => null)) as CloudflareImageResponse | null;
  const imageBase64 = payload?.result?.image;
  if (!response.ok || payload?.success === false || !imageBase64) {
    const providerMessage = payload?.errors?.map((item) => item.message).filter(Boolean).join("; ");
    console.error("[JIB Cloudflare AI]", {
      status: response.status,
      errors: providerMessage ?? "No image returned",
    });
    if (response.status === 401 || response.status === 403) {
      throw new Error("CLOUDFLARE_AUTH_FAILED");
    }
    if (response.status === 429) {
      throw new Error("CLOUDFLARE_QUOTA_OR_RATE_LIMIT");
    }
    throw new Error("CLOUDFLARE_GENERATION_FAILED");
  }

  const image = Buffer.from(imageBase64, "base64");
  if (!image.byteLength || image.byteLength > MAX_IMAGE_BYTES) {
    throw new Error("Generated image is empty or exceeds the 5 MB storage limit.");
  }
  return new Uint8Array(image);
}

export async function POST(request: Request) {
  let jobId: string | null = null;
  let supabase: SupabaseClient<Database> | null = null;

  try {
    // Validate provider configuration before reserving a monthly image slot.
    const cloudflareAccountId = process.env.CLOUDFLARE_ACCOUNT_ID?.trim() ?? "";
    const cloudflareApiToken = process.env.CLOUDFLARE_API_TOKEN?.trim() ?? "";
    if (!/^[a-f0-9]{32}$/i.test(cloudflareAccountId) || !cloudflareApiToken) {
      return jsonError("مولّد الصور غير مربوط بعد أو أن Account ID غير صالح. أضف بيانات Cloudflare السرية الصحيحة إلى إعدادات Vercel ثم أعد النشر.", 503);
    }

    const authorization = request.headers.get("authorization") ?? "";
    if (!authorization.startsWith("Bearer ")) {
      return jsonError("يجب تسجيل الدخول قبل إنشاء الصور.", 401);
    }

    const token = authorization.slice("Bearer ".length).trim();
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!supabaseUrl || !anonKey) {
      return jsonError("خدمة قاعدة البيانات غير مهيأة على الخادم.", 503);
    }

    supabase = createClient<Database>(supabaseUrl, anonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
      global: { headers: { Authorization: `Bearer ${token}` } },
    });

    const { data: userResult, error: authError } = await supabase.auth.getUser(token);
    if (authError || !userResult.user) {
      return jsonError("انتهت جلسة الدخول. سجّل الدخول مجدداً.", 401);
    }

    const body = (await request.json()) as ImageRequest;
    const type = body.type;
    if (type !== "product" && type !== "article") {
      return jsonError("نوع طلب الصورة غير صالح.", 400);
    }
    if (type === "product" && !body.productId) {
      return jsonError("معرّف المنتج مطلوب.", 400);
    }
    if (type === "article" && (!body.title?.trim() || !body.description?.trim())) {
      return jsonError("عنوان المقال وملخصه مطلوبان.", 400);
    }

    const imageRpc = supabase as unknown as ImageJobRpcClient;
    const { data: reserved, error: reserveError } = await imageRpc.rpc(
      "jib_ai_manager_reserve_image_job",
      {
        p_request_type: type,
        p_product_id: type === "product" ? body.productId : null,
        p_title: type === "article" ? body.title?.trim() : null,
        p_description: body.description?.trim() ?? null,
      },
    );

    if (reserveError) {
      const quotaReached = reserveError.message.toLowerCase().includes("monthly ai image limit");
      return jsonError(
        quotaReached ? "تم بلوغ حد الصور الشهري (100 صورة). حاول مجدداً الشهر القادم." : "لا تملك صلاحية إنشاء هذه الصورة أو أن بيانات الطلب غير مكتملة.",
        quotaReached ? 429 : 403,
      );
    }

    const job = (Array.isArray(reserved) ? reserved[0] : reserved) as ReservedImageJob | null;
    if (!job?.job_id) return jsonError("تعذر حجز طلب إنشاء الصورة.", 500);
    jobId = String(job.job_id);

    const prompt = buildPrompt(type, String(job.title), String(job.description));
    const imageBytes = await generateWithCloudflare(prompt);
    const bucket = type === "product" ? "product-images" : "article-images";
    const storagePath = type === "product"
      ? `${job.store_id}/ai-drafts/${jobId}.jpg`
      : `articles/${jobId}.jpg`;

    const { error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(storagePath, Buffer.from(imageBytes), {
        contentType: "image/jpeg",
        upsert: false,
      });
    if (uploadError) throw new Error(`Image storage upload failed: ${uploadError.message}`);

    const { data: publicData } = supabase.storage.from(bucket).getPublicUrl(storagePath);
    const imageUrl = publicData.publicUrl;
    const { error: finishError } = await imageRpc.rpc("jib_ai_manager_finish_image_job", {
      p_job_id: jobId,
      p_image_url: imageUrl,
      p_storage_bucket: bucket,
      p_storage_path: storagePath,
      p_model: IMAGE_MODEL,
      p_estimated_cost_usd: ESTIMATED_COST_USD,
    });
    if (finishError) throw new Error(`Could not finalize image job: ${finishError.message}`);

    return NextResponse.json({
      jobId,
      imageUrl,
      status: "ready_for_review",
      model: IMAGE_MODEL,
      estimatedCostUsd: ESTIMATED_COST_USD,
      aiGenerated: true,
      approvalRequired: true,
    });
  } catch (error) {
    const code = error instanceof Error ? error.message : "UNKNOWN";
    if (jobId && supabase) {
      try {
        await (supabase as unknown as ImageJobRpcClient).rpc("jib_ai_manager_fail_image_job", {
          p_job_id: jobId,
          p_error_message: code.slice(0, 400),
        });
      } catch {
        // Preserve the original generation error if the failure logger is unavailable.
      }
    }

    if (code === "CLOUDFLARE_NOT_CONFIGURED") {
      return jsonError("مولّد الصور غير مربوط بعد. أضف بيانات Cloudflare السرية إلى إعدادات Vercel.", 503);
    }
    if (code === "CLOUDFLARE_AUTH_FAILED") {
      return jsonError("رفض Cloudflare بيانات الربط. تحقق من Account ID وصلاحيات Workers AI في API Token.", 502);
    }
    if (code === "CLOUDFLARE_QUOTA_OR_RATE_LIMIT") {
      return jsonError("وصل Cloudflare إلى حد الاستخدام أو معدل الطلبات. انتظر تجدد الحصة ثم أعد المحاولة.", 429);
    }
    console.error("[JIB AI image generation]", error);
    return jsonError("تعذر إنشاء الصورة حالياً عبر Cloudflare Workers AI. حاول مجدداً لاحقاً.", 503);
  }
}
