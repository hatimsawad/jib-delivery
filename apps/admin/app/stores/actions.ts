"use server";

import { revalidatePath } from "next/cache";
import { requireAdmin } from "../admin-data";

type StoreStatusRpcClient = {
  rpc(
    functionName: "admin_set_store_status",
    args: { p_store_id: string; p_is_active: boolean; p_is_open: boolean },
  ): Promise<{ error: { message: string } | null }>;
};

const fulfillmentModes = [
  "courier_places_order",
  "jib_central_order",
  "store_digital_order",
  "partner_api_pos",
] as const;

const orderPermissionStatuses = [
  "not_required",
  "pending",
  "approved",
  "rejected",
  "suspended",
] as const;

const loyaltyModes = [
  "none",
  "jib_business_account",
  "partner_business_account",
  "jib_rewards",
] as const;

const loyaltyPermissionStatuses = [
  "not_required",
  "pending",
  "approved",
  "rejected",
  "suspended",
] as const;

function formValue(formData: FormData, key: string, maxLength = 1000) {
  return String(formData.get(key) ?? "").trim().slice(0, maxLength);
}

export async function setStoreStatus(formData: FormData) {
  const storeId = String(formData.get("storeId") ?? "");
  const isActive = String(formData.get("isActive") ?? "") === "true";
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(storeId)) {
    throw new Error("Invalid store id.");
  }

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

export async function saveStoreBranchPolicy(formData: FormData) {
  const storeId = formValue(formData, "storeId", 36);
  const fulfillmentMode = formValue(formData, "fulfillmentMode", 40);
  let orderPermissionStatus = formValue(formData, "orderPermissionStatus", 24);
  const orderChannelUrl = formValue(formData, "orderChannelUrl", 500);
  const orderPermissionReference = formValue(formData, "orderPermissionReference", 500);
  const loyaltyMode = formValue(formData, "loyaltyMode", 32);
  let loyaltyPermissionStatus = formValue(formData, "loyaltyPermissionStatus", 24);
  const loyaltyPermissionReference = formValue(formData, "loyaltyPermissionReference", 500);
  const loyaltyProgramName = formValue(formData, "loyaltyProgramName", 120);
  const operatorNotes = formValue(formData, "operatorNotes", 1000);

  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(storeId)) {
    throw new Error("معرّف الفرع غير صالح.");
  }
  if (!(fulfillmentModes as readonly string[]).includes(fulfillmentMode)) {
    throw new Error("طريقة تنفيذ الطلب غير صالحة.");
  }
  if (!(orderPermissionStatuses as readonly string[]).includes(orderPermissionStatus)) {
    throw new Error("حالة موافقة الفرع غير صالحة.");
  }
  if (!(loyaltyModes as readonly string[]).includes(loyaltyMode)) {
    throw new Error("طريقة الولاء غير صالحة.");
  }
  if (!(loyaltyPermissionStatuses as readonly string[]).includes(loyaltyPermissionStatus)) {
    throw new Error("حالة موافقة برنامج الولاء غير صالحة.");
  }

  if (fulfillmentMode !== "courier_places_order" && orderPermissionStatus === "not_required") {
    throw new Error("اختر حالة موافقة الفرع: بانتظار الموافقة أو موافقة موثقة أو مرفوضة أو موقوفة.");
  }

  if (orderPermissionStatus === "approved" && !orderPermissionReference) {
    throw new Error("أدخل مرجعاً يوضح كيفية توثيق موافقة الفرع قبل اعتماد الطلب المركزي.");
  }

  if (fulfillmentMode === "store_digital_order" && orderPermissionStatus === "approved") {
    let parsedUrl: URL;
    try {
      parsedUrl = new URL(orderChannelUrl);
    } catch {
      throw new Error("أدخل رابط HTTPS الرسمي لطلب المتجر قبل اعتماد القناة الرقمية.");
    }
    if (parsedUrl.protocol !== "https:") {
      throw new Error("يجب أن يبدأ رابط الطلب الرسمي بـ HTTPS.");
    }
  }

  if (loyaltyMode === "jib_business_account" || loyaltyMode === "partner_business_account") {
    if (loyaltyPermissionStatus === "not_required") {
      throw new Error("اختر حالة موافقة برنامج الولاء الخارجي.");
    }
    if (loyaltyPermissionStatus === "approved" && (!loyaltyProgramName || !loyaltyPermissionReference)) {
      throw new Error("يتطلب اعتماد برنامج الولاء الخارجي اسمه ومرجع الموافقة الموثقة.");
    }
  } else {
    loyaltyPermissionStatus = "not_required";
  }

  const { supabase, user } = await requireAdmin();
  const { error } = await supabase.from("store_branch_policies").upsert({
    store_id: storeId,
    fulfillment_mode: fulfillmentMode,
    order_permission_status: orderPermissionStatus,
    order_channel_url: orderChannelUrl || null,
    order_permission_approved_at: orderPermissionStatus === "approved" ? new Date().toISOString() : null,
    order_permission_approved_by: orderPermissionStatus === "approved" ? user.id : null,
    order_permission_reference: orderPermissionStatus === "approved" ? orderPermissionReference : null,
    loyalty_mode: loyaltyMode,
    loyalty_program_name: loyaltyMode === "none" ? null : (loyaltyProgramName || (loyaltyMode === "jib_rewards" ? "JIB Rewards" : null)),
    loyalty_permission_status: loyaltyPermissionStatus,
    loyalty_permission_approved_at: loyaltyPermissionStatus === "approved" ? new Date().toISOString() : null,
    loyalty_permission_approved_by: loyaltyPermissionStatus === "approved" ? user.id : null,
    loyalty_permission_reference: loyaltyPermissionStatus === "approved" ? loyaltyPermissionReference : null,
    operator_notes: operatorNotes || null,
    updated_by: user.id,
    updated_at: new Date().toISOString(),
  }, { onConflict: "store_id" });

  if (error) throw new Error(error.message);
  revalidatePath("/stores");
  revalidatePath("/orders");
}
