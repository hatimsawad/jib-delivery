"use server";

import { revalidatePath } from "next/cache";
import { requireAdmin } from "../admin-data";

const categories = [
  "prepared-food", "bakery", "beverages", "grocery", "fresh-produce",
  "meat-seafood", "household", "personal-care", "electronics", "fashion",
  "beauty", "flowers-gifts", "toys-games", "books-stationery", "pet-supplies",
  "sports-outdoors", "automotive", "pharmacy", "general-merchandise",
] as const;

const statuses = ["draft", "pending_verification", "approved", "rejected", "suspended"] as const;

function value(data: FormData, key: string, max = 300) {
  return String(data.get(key) ?? "").trim().slice(0, max);
}

type BrandAdminClient = {
  from(table: "commercial_brands"): {
    insert(values: Record<string, unknown>): Promise<{ error: { message: string } | null }>;
    update(values: Record<string, unknown>): {
      eq(column: "id", value: string): Promise<{ error: { message: string } | null }>;
    };
  };
};

export async function createCommercialBrand(data: FormData) {
  const name = value(data, "name", 120);
  const slug = value(data, "slug", 100).toLowerCase();
  const category = value(data, "category", 40);
  const website = value(data, "websiteUrl", 300);
  const country = value(data, "countryCode", 2).toUpperCase();
  const sourceName = value(data, "sourceName", 120);
  const sourceUrl = value(data, "sourceUrl", 300);
  if (!name || !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) throw new Error("أدخل اسماً ورابطاً مختصراً صالحاً للعلامة.");
  if (!(categories as readonly string[]).includes(category)) throw new Error("فئة العلامة غير صالحة.");
  if (country && !/^[A-Z]{2}$/.test(country)) throw new Error("رمز الدولة يجب أن يتكون من حرفين.");
  for (const url of [website, sourceUrl]) {
    if (!url) continue;
    let parsed: URL;
    try { parsed = new URL(url); } catch { throw new Error("أدخل رابطاً صالحاً يبدأ بـ HTTPS."); }
    if (parsed.protocol !== "https:") throw new Error("يجب أن تكون الروابط HTTPS.");
  }
  const normalizedName = name.toLocaleLowerCase().normalize("NFKD").replace(/[\\u064B-\\u065F\\u0670\\u0640]/g, "").replace(/[^\\p{L}\\p{N}]+/gu, " ").trim().replace(/\\s+/g, " ");
  const { supabase, user } = await requireAdmin();
  const client = supabase as unknown as BrandAdminClient;
  const { error } = await client.from("commercial_brands").insert({
    name, normalized_name: normalizedName, slug, category,
    website_url: website || null, country_code: country || null,
    status: "pending_verification", source_name: sourceName || null,
    source_url: sourceUrl || null, created_by: user.id,
  });
  if (error) throw new Error(error.message);
  revalidatePath("/brands");
}

export async function updateCommercialBrandStatus(data: FormData) {
  const id = value(data, "brandId", 36);
  const status = value(data, "status", 30);
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) throw new Error("معرّف العلامة غير صالح.");
  if (!(statuses as readonly string[]).includes(status)) throw new Error("حالة العلامة غير صالحة.");
  const { supabase } = await requireAdmin();
  const client = supabase as unknown as BrandAdminClient;
  const { error } = await client.from("commercial_brands").update({
    status, verified_at: status === "approved" ? new Date().toISOString() : null,
  }).eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/brands");
}
