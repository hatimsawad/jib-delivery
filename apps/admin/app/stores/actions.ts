"use server";

import { revalidatePath } from "next/cache";
import { requireAdmin } from "../admin-data";

type StoreStatusRpcClient = {
  rpc(
    functionName: "admin_set_store_status",
    args: { p_store_id: string; p_is_active: boolean; p_is_open: boolean },
  ): Promise<{ error: { message: string } | null }>;
};

export async function setStoreStatus(formData: FormData) {
  const storeId = String(formData.get("storeId") ?? "");
  const isActive = String(formData.get("isActive") ?? "") === "true";
  if (!/^[0-9a-f-]{36}$/i.test(storeId)) throw new Error("Invalid store id.");

  const { supabase } = await requireAdmin();
  const adminRpc = supabase as unknown as StoreStatusRpcClient;
  const { error } = await adminRpc.rpc("admin_set_store_status", {
    p_store_id: storeId,
    p_is_active: isActive,
    p_is_open: isActive,
  });
  if (error) throw new Error(error.message);
  revalidatePath("/stores");
}
