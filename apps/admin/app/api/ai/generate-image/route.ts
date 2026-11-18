import { generateImage } from "ai";
import { Buffer } from "node:buffer";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "../../../../types/database.types";
import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const maxDuration = 60;
export const dynamic = "force-dynamic";

const IMAGE_MODEL = "bfl/flux-3-image-klein";
const ESTIMATED_COST_USD = 0.009;
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

type ImageRequest = {
  type?: "product" | "article";
  productId?: string;
  title?: string;
  description?: string;
};

function jsonError(message: string, status: number) {
  return NextResponse.json({ error: message }, { status });
}

function buildPrompt(type: "product" | "article", title: string, description: string) {
  if (type === "product") {
    return [
      "Create one premium, photorealistic food photograph for a Moroccan food-delivery marketplace.",
      `Dish name: ${title}.`,
      `Ingredients and restaurant description: ${description}.`,
      "Ingredient fidelity is essential: depict only the ingredients and preparation details supplied. Do not invent meat, seafood, dairy, nuts, sauces, toppings, or allergens that are not mentioned.",
      "Show the finished dish as it would actually be served, appetizing but realistic, with natural textures, accurate proportions, soft studio daylight, and a clean neutral tabletop.",
      "Single dish, centered composition, square 1:1 framing, high-end commercial restaurant photography.",
      "No text, no typography, no menu labels, no logos, no watermarks, no packaging, no people, no extra dishes.",
    ].join(" ");
  }

  return [
    "Create one premium editorial cover image for a JIB article.",
    `Article title: ${title}.`,
    `Article summary and context: ${description}.`,
    "Create a clear visual metaphor for the article's central idea, with a refined modern Moroccan editorial feel, strong subject hierarchy, natural lighting, and polished composition.",
    "Landscape 16:9 framing suitable for a website article cover.",
    "No text, no typography, no logos, no watermarks, no fabricated charts or labels.",
  ].join(" ");
}

export async function POST(request: Request) {
  let jobId: string | null = null;
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

    const { data: reserved, error: reserveError } = await supabase.rpc(
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

    const job = Array.isArray(reserved) ? reserved[0] : reserved;
    if (!job?.job_id) {
      return jsonError("تعذر حجز طلب إنشاء الصورة.", 500);
    }
    jobId = String(job.job_id);

    const prompt = buildPrompt(type, String(job.title), String(job.description));
    const { image } = await generateImage({
      model: IMAGE_MODEL,
      prompt,
      aspectRatio: type === "product" ? "1:1" : "16:9",
    });

    if (!image.uint8Array?.byteLength || image.uint8Array.byteLength > MAX_IMAGE_BYTES) {
      throw new Error("Generated image is empty or exceeds the 5 MB storage limit.");
    }
    if (!["image/png", "image/jpeg", "image/webp"].includes(image.mediaType)) {
      throw new Error("Generated image format is not allowed by JIB storage.");
    }

    const bucket = type === "product" ? "product-images" : "article-images";
    const extension = image.mediaType === "image/jpeg" ? "jpg" : image.mediaType === "image/webp" ? "webp" : "png";
    const storagePath = type === "product"
      ? `${job.store_id}/ai-drafts/${jobId}.${extension}`
      : `articles/${jobId}.${extension}`;

    const { error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(storagePath, Buffer.from(image.uint8Array), {
        contentType: image.mediaType || "image/png",
        upsert: false,
      });

    if (uploadError) {
      throw new Error(`Image storage upload failed: ${uploadError.message}`);
    }

    const { data: publicData } = supabase.storage.from(bucket).getPublicUrl(storagePath);
    const imageUrl = publicData.publicUrl;

    const { error: finishError } = await supabase.rpc("jib_ai_manager_finish_image_job", {
      p_job_id: jobId,
      p_image_url: imageUrl,
      p_storage_bucket: bucket,
      p_storage_path: storagePath,
      p_model: IMAGE_MODEL,
      p_estimated_cost_usd: ESTIMATED_COST_USD,
    });

    if (finishError) {
      throw new Error(`Could not finalize image job: ${finishError.message}`);
    }

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
    if (jobId && supabase) {
      const safeMessage = error instanceof Error ? error.message.slice(0, 400) : "Image generation failed";
      try {
        await supabase.rpc("jib_ai_manager_fail_image_job", {
          p_job_id: jobId,
          p_error_message: safeMessage,
        });
      } catch {
        // Preserve the original generation error if the failure logger is unavailable.
      }
    }
    console.error("[JIB AI image generation]", error);
    return jsonError("تعذر إنشاء الصورة حالياً. تحقق من ربط AI Gateway ثم أعد المحاولة.", 503);
  }
}
