"use server";

import { revalidatePath } from "next/cache";
import { requireAdmin } from "../admin-data";

export async function setCourierActive(formData: FormData) {
  const userId = String(formData.get("userId") ?? "");
  const isActive = String(formData.get("isActive") ?? "") === "true";
  if (!/^[0-9a-f-]{36}$/i.test(userId)) throw new Error("Invalid courier id.");

  const { supabase } = await requireAdmin();
  const { error } = await supabase.rpc("admin_set_courier_active", {
    p_user_id: userId,
    p_active: isActive,
  });
  if (error) throw new Error(error.message);
  revalidatePath("/users");
}
