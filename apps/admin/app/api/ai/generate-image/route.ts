import { Buffer } from "node:buffer";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "../../../../types/database.types";
import { buildCommercialProductPrompt } from "../../../../lib/ai/commercial-catalog";
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
  const safeTitle = title.trim().replace(/\s+/g, " ").slice(0, 180);
  const safeDescription = description.trim().replace(/\s+/g, " ").slice(0, 1_100);

  if (type === "product") {
    return buildCommercialProductPrompt(safeTitle, safeDescription);
  }

  const dishPrompt = buildMoroccanDishPrompt(`${safeTitle} ${safeDescription}`);
  if (dishPrompt) {
    return [
      dishPrompt,
      `Editorial cover subject: ${safeTitle}.`,
      `Article context: ${safeDescription}.`,
      "The named Moroccan dish remains the single hero subject. Make the authentic food and its defining serving vessel clearly recognizable, with close-up editorial food photography, natural directional light, realistic textures, and a clean square 1:1 composition.",
      "No people, cooks, kitchens, restaurant interiors, text, logos, watermarks, labels, or unrelated dishes.",
    ].join(" ").slice(0, 2048);
  }

  const articlePrompt = [
    "Create a premium photorealistic editorial photograph for a JIB magazine article.",
    `Exact article subject: ${safeTitle}.`,
    `Article context: ${safeDescription}.`,
    "Build one clear, visually compelling scene that accurately represents the article context. Use refined contemporary Moroccan editorial art direction, one dominant subject, thoughtful negative space, realistic materials, and natural directional lighting.",
    "Professional editorial photography, natural colors, crisp subject detail, subtle depth of field, polished square 1:1 composition.",
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
        Accept: "application/json",
      },
      body: JSON.stringify({ prompt, steps: 8 }),
      signal: AbortSignal.timeout(45_000),
      cache: "no-store",
    },
  );

  const responseText = await response.text();
  let payload: CloudflareImageResponse | null = null;
  try {
    payload = JSON.parse(responseText) as CloudflareImageResponse;
  } catch {
    payload = null;
  }

  const imageBase64 = payload?.result?.image;
  if (!response.ok || payload?.success === false || typeof imageBase64 !== "string" || !imageBase64) {
    const providerMessage = payload?.errors?.map((item) => item.message).filter(Boolean).join("; ") ?? "";
    const safeProviderMessage = providerMessage
      .replace(/Bearer\\s+[^\\s,;]+/gi, "Bearer [redacted]")
      .replace(/(api[_-]?token|secret)[=: ]+[^\\s,;]+/gi, "$1=[redacted]")
      .slice(0, 240);
    console.error("[JIB Cloudflare AI]", {
      status: response.status,
      contentType: response.headers.get("content-type"),
      errors: safeProviderMessage || (payload ? "No image returned" : "Invalid JSON response"),
    });

    if (response.status === 401) throw new Error("CLOUDFLARE_AUTH_FAILED");
    if (response.status === 403) {
      if (/quota|limit|neuron|upgrade|plan|payment|billing/i.test(providerMessage)) {
        throw new Error("CLOUDFLARE_FREE_LIMIT_REACHED");
      }
      throw new Error("CLOUDFLARE_AUTH_FAILED");
    }
    if (response.status === 429) throw new Error("CLOUDFLARE_QUOTA_OR_RATE_LIMIT");
    if ([502, 503, 504].includes(response.status)) throw new Error("CLOUDFLARE_CAPACITY");
    throw new Error(`CLOUDFLARE_GENERATION_FAILED:${response.status}`);
  }

  if (!/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(imageBase64)) {
    throw new Error("CLOUDFLARE_BAD_OUTPUT");
  }

  const image = Buffer.from(imageBase64, "base64");
  const isJpeg = image.byteLength >= 3 && image[0] === 0xff && image[1] === 0xd8 && image[2] === 0xff;
  if (!isJpeg || image.byteLength > MAX_IMAGE_BYTES) {
    throw new Error("CLOUDFLARE_BAD_OUTPUT");
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
    if (code === "CLOUDFLARE_FREE_LIMIT_REACHED") {
      return jsonError("توقفت الخدمة لأن حصة Cloudflare المجانية غير متاحة حالياً أو أن الخطة تتطلب ترقية. لم نفعّل أي ترقية أو دفع؛ حاول بعد تجدد الحصة المجانية.", 429);
    }
    if (code === "CLOUDFLARE_QUOTA_OR_RATE_LIMIT") {
      return jsonError("وصل Cloudflare إلى حد الاستخدام المجاني أو معدل الطلبات. لم يتم تفعيل أي فوترة؛ أعد المحاولة بعد تجدد الحصة.", 429);
    }
    if (code === "CLOUDFLARE_CAPACITY") {
      return jsonError("خدمة توليد الصور لدى Cloudflare مزدحمة مؤقتاً. لم تُحتسب الصورة؛ أعد المحاولة لاحقاً.", 503);
    }
    if (code === "CLOUDFLARE_BAD_OUTPUT") {
      return jsonError("أعاد نموذج الصور ملفاً غير صالح أو أكبر من الحد المسموح. لم نحفظ ملفاً تالفاً.", 502);
    }
    if (code.startsWith("CLOUDFLARE_GENERATION_FAILED:")) {
      return jsonError(`رفض Cloudflare طلب الصورة (HTTP ${code.split(":")[1] ?? "unknown"}). راجع صلاحيات Workers AI وحالة الخدمة؛ لم نقم بالترقية أو تشغيل الدفع.`, 502);
    }
    if (code.startsWith("Image storage upload failed:")) {
      console.error("[JIB AI image storage]", code);
      return jsonError("تم إنشاء الصورة لدى Cloudflare لكن تعذر حفظها في مخزن JIB. تحقق من صلاحيات التخزين ثم أعد المحاولة.", 502);
    }
    if (code.startsWith("Could not finalize image job:")) {
      console.error("[JIB AI image finalization]", code);
      return jsonError("تم رفع الصورة لكن تعذر تسجيلها في سجل المهام. أوقفنا نشرها تلقائياً حتى لا تظهر صورة غير معتمدة.", 502);
    }
    if (code === "TimeoutError" || code === "AbortError") {
      return jsonError("استغرق توليد الصورة وقتاً أطول من المسموح. لم نفعّل أي خدمة مدفوعة؛ أعد المحاولة لاحقاً.", 504);
    }
    console.error("[JIB AI image generation]", error);
    return jsonError(jobId
      ? `تعذر إكمال طلب الصورة. رقم المهمة: ${jobId}`
      : "تعذر بدء طلب الصورة. تحقق من تسجيل الدخول وإعدادات JIB Manager.", 503);
  }
}
