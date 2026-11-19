import { Buffer } from "node:buffer";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "../../../../types/database.types";
import { buildMoroccanDishPrompt } from "../../../../lib/ai/moroccan-dishes";
import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const maxDuration = 60;
export const dynamic = "force-dynamic";

const IMAGE_MODEL = "cloudflare/@cf/black-forest-labs/flux-1-schnell";
const CLOUDFLARE_MODEL = "@cf/black-forest-labs/flux-1-schnell";
const ESTIMATED_COST_USD = 0.000933; // 8-step, single 512px-tile list-price estimate; Workers AI free quota remains unbilled.
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
  const safeTitle = title.trim().replace(/\\s+/g, " ").slice(0, 180);
  const safeDescription = description.trim().replace(/\\s+/g, " ").slice(0, 1_100);

  if (type === "product") {
    // Match against both the product name and its ingredient description.
    // Put the regional dish definition FIRST so the model cannot lose it
    // when the provider enforces its 2,048-character prompt limit.
    const dishReferencePrompt = buildMoroccanDishPrompt(
      `${safeTitle} ${safeDescription}`,
    );
    const photographyPrompt = [
      "Photograph the actual prepared food product itself, not a person, cook, kitchen, restaurant, room, ingredients-only scene, or lifestyle scene.",
      "Premium photorealistic commercial food photography for a Moroccan food-delivery marketplace.",
      `Exact product: ${safeTitle}.`,
      `Use only these supplied ingredients and preparation details: ${safeDescription}.`,
      "One real serving, close-up three-quarter hero angle, food fills most of the square frame, crisp realistic food textures, natural appetizing colors, soft directional studio-window light, subtle depth of field, simple warm-neutral tabletop.",
      "No text, typography, labels, logos, watermarks, borders, people, hands, or unrelated props.",
    ].join(" ");
    const prompt = dishReferencePrompt
      ? `${dishReferencePrompt} ${photographyPrompt}`
      : photographyPrompt;
    return prompt.slice(0, 2048);
  }

  const articlePrompt = [
    "Create a premium photorealistic editorial photograph for a JIB magazine article.",
    `Exact article subject: ${safeTitle}.`,
    `Article context: ${safeDescription}.`,
    "Build one clear, visually compelling scene that accurately represents the article context. Use refined contemporary Moroccan editorial art direction, one dominant subject, thoughtful negative space, realistic materials, and natural directional lighting.",
    "Professional editorial photography, natural colors, crisp subject detail, subtle depth of field, polished landscape 16:9 composition.",
    "No text, typography, logos, watermarks, invented charts, labels, or UI elements.",
  ].join(" ");
  return articlePrompt.slice(0, 2048);
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
      body: JSON.stringify({ prompt, steps: 8 }),
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
  let uploadedBucket: string | null = null;
  let uploadedStoragePath: string | null = null;
  let supabase: SupabaseClient<Database> | null = null;

  try {
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

    // Validate provider configuration before reserving a monthly image slot.
    const cloudflareAccountId = process.env.CLOUDFLARE_ACCOUNT_ID?.trim() ?? "";
    const cloudflareApiToken = process.env.CLOUDFLARE_API_TOKEN?.trim() ?? "";
    if (!/^[a-f0-9]{32}$/i.test(cloudflareAccountId) || !cloudflareApiToken) {
      return jsonError("مولّد الصور غير مربوط بعد أو أن Account ID غير صالح. أضف بيانات Cloudflare السرية الصحيحة إلى إعدادات Vercel ثم أعد النشر.", 503);
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
    uploadedBucket = bucket;
    uploadedStoragePath = storagePath;

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
    uploadedBucket = null;
    uploadedStoragePath = null;

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
    if (uploadedBucket && uploadedStoragePath && supabase) {
      try {
        await supabase.storage.from(uploadedBucket).remove([uploadedStoragePath]);
      } catch {
        console.error("[JIB AI image cleanup] Could not remove unfinalized image object.");
      }
    }
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
