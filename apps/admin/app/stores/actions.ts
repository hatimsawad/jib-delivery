"use server";

import { revalidatePath } from "next/cache";
import { requireAdmin } from "../admin-data";

export async function setStoreStatus(formData: FormData) {
  const storeId = String(formData.get("storeId") ?? "");
  const isActive = String(formData.get("isActive") ?? "") === "true";
  if (!/^[0-9a-f-]{36}$/i.test(storeId)) throw new Error("Invalid store id.");

  const { supabase } = await requireAdmin();
  const { error } = await supabase.rpc("admin_set_store_status", {
    p_store_id: storeId,
    p_is_active: isActive,
    p_is_open: isActive,
  });
  if (error) throw new Error(error.message);
  revalidatePath("/stores");
}
