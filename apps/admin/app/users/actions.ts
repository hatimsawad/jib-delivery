"use server";

import { revalidatePath } from "next/cache";
import { requireAdmin } from "../admin-data";

type CourierApprovalRpcClient = {
  rpc(
    functionName: "admin_set_courier_active",
    args: { p_user_id: string; p_active: boolean },
  ): Promise<{ error: { message: string } | null }>;
};

export async function setCourierActive(formData: FormData) {
  const userId = String(formData.get("userId") ?? "");
  const isActive = String(formData.get("isActive") ?? "") === "true";
  if (!/^[0-9a-f-]{36}$/i.test(userId)) throw new Error("Invalid courier id.");

  const { supabase } = await requireAdmin();
  const adminRpc = supabase as unknown as CourierApprovalRpcClient;
  const { error } = await adminRpc.rpc("admin_set_courier_active", {
    p_user_id: userId,
    p_active: isActive,
  });
  if (error) throw new Error(error.message);
  revalidatePath("/users");
}
