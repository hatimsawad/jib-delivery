import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";
import { saveStoreBranchPolicy, setStoreStatus } from "./actions";

type StoreRow = {
  id: string; name: string; category: string; phone: string | null;
  address_text: string | null; is_active: boolean; is_open: boolean; onboarding_status: string; created_at: string;
};

type BranchPolicyRow = {
  id: string;
  store_id: string;
  fulfillment_mode: string;
  order_permission_status: string;
  order_channel_url: string | null;
  order_permission_reference: string | null;
  loyalty_mode: string;
  loyalty_program_name: string | null;
  loyalty_permission_status: string;
  loyalty_permission_reference: string | null;
  operator_notes: string | null;
};

const fulfillmentLabels: Record<string, string> = {
  courier_places_order: "المندوب يقدّم الطلب في الفرع",
  jib_central_order: "JIB يقدّم الطلب مركزياً",
  store_digital_order: "قناة المتجر الرقمية الرسمية",
  partner_api_pos: "تكامل API / POS معتمد",
};

const orderPermissionLabels: Record<string, string> = {
  not_required: "غير مطلوب",
  pending: "بانتظار الموافقة",
  approved: "موافقة موثقة",
  rejected: "مرفوضة",
  suspended: "موقوفة",
};

const loyaltyLabels: Record<string, string> = {
  none: "لا يوجد برنامج مرتبط",
  jib_business_account: "حساب ولاء تجاري خاص بـ JIB",
  partner_business_account: "حساب ولاء تجاري مشترك",
  jib_rewards: "مكافآت JIB",
};

const loyaltyPermissionLabels: Record<string, string> = {
  not_required: "غير مطلوب",
  pending: "بانتظار الموافقة",
  approved: "موافقة موثقة",
  rejected: "مرفوضة",
  suspended: "موقوفة",
};

export const dynamic = "force-dynamic";

export default async function StoresPage() {
  const { supabase } = await requireAdmin();
  const [{ data, error }, { data: policyData, error: policyError }] = await Promise.all([
    supabase.from("stores")
      .select("id,name,category,phone,address_text,is_active,is_open,onboarding_status,created_at")
      .order("created_at", { ascending: false }).limit(100),
    supabase.from("store_branch_policies")
      .select("id,store_id,fulfillment_mode,order_permission_status,order_channel_url,order_permission_reference,loyalty_mode,loyalty_program_name,loyalty_permission_status,loyalty_permission_reference,operator_notes"),
  ]);

  const stores = (data ?? []) as unknown as StoreRow[];
  const policies = new Map(
    ((policyData ?? []) as unknown as BranchPolicyRow[]).map((policy) => [policy.store_id, policy]),
  );
  const categories: Record<string, string> = { restaurant: "مطعم", grocery: "بقالة", shop: "متجر" };

  return <main className="shell">
    <AdminHeader />
    <section className="page-heading">
      <p className="eyebrow">الشركاء المحليون والفروع</p>
      <h1>المتاجر والفروع</h1>
      <p>كل فرع له طريقة تنفيذ مستقلة. لا يُسمح لـJIB بتقديم الطلب أو جمع نقاط برنامج خارجي إلا بعد تسجيل موافقة ذلك الفرع.</p>
    </section>

    <section className="list-panel">
      <div className="section-heading"><h2>قائمة المتاجر والفروع</h2><span className="count-chip">{stores.length} فرع</span></div>
      {error ? <p className="error-state">تعذر تحميل المتاجر. تحقق من صلاحيات قاعدة البيانات.</p> :
        stores.length === 0 ? <div className="empty-state"><strong>لم تتم إضافة متاجر بعد</strong><span>يمكن للتجار إنشاء حساباتهم، وستظهر طلبات متاجرهم هنا لاعتمادها.</span></div> :
        <div className="table-wrap"><table><thead><tr><th>المتجر / الفرع</th><th>الفئة</th><th>العنوان</th><th>الهاتف</th><th>الحالة</th><th>اعتماد المتجر</th><th>إعدادات الفرع</th></tr></thead>
          <tbody>{stores.map((store) => {
            const policy = policies.get(store.id);
            return <tr key={store.id}>
              <td><strong>{store.name}</strong></td>
              <td>{categories[store.category] ?? store.category}</td>
              <td>{store.address_text || "—"}</td>
              <td>{store.phone || "—"}</td>
              <td><span className={store.onboarding_status === "approved" && store.is_active ? "status-pill status-good" : "status-pill"}>{store.onboarding_status !== "approved" ? (store.onboarding_status === "suspended" ? "موقوف" : store.onboarding_status === "rejected" ? "مرفوض" : "بانتظار الاعتماد") : (store.is_active ? (store.is_open ? "معتمد ومفتوح" : "معتمد ومغلق") : "معتمد وغير نشط")}</span></td>
              <td><form action={setStoreStatus}>
                <input type="hidden" name="storeId" value={store.id} />
                <input type="hidden" name="isActive" value={String(!store.is_active || store.onboarding_status !== "approved")} />
                <button className="logout-button inline-action" type="submit">{store.is_active && store.onboarding_status === "approved" ? "إيقاف المتجر" : "اعتماد وفتح المتجر"}</button>
              </form></td>
              <td>
                <details className="branch-policy-details">
                  <summary>إعدادات الطلب والولاء</summary>
                  <div className="branch-policy-summary">
                    <span>طريقة التنفيذ: <strong>{fulfillmentLabels[policy?.fulfillment_mode ?? "courier_places_order"]}</strong></span>
                    <span>الولاء: <strong>{loyaltyLabels[policy?.loyalty_mode ?? "none"]}</strong></span>
                  </div>
                  <form action={saveStoreBranchPolicy} className="branch-policy-form">
                    <input type="hidden" name="storeId" value={store.id} />
                    <div className="branch-policy-grid">
                      <label>طريقة تنفيذ الطلب
                        <select name="fulfillmentMode" defaultValue={policy?.fulfillment_mode ?? "courier_places_order"}>
                          <option value="courier_places_order">المندوب يقدّم الطلب في الفرع</option>
                          <option value="jib_central_order">JIB يقدّم الطلب مركزياً (يتطلب موافقة)</option>
                          <option value="store_digital_order">JIB يطلب عبر التطبيق / الموقع الرسمي</option>
                          <option value="partner_api_pos">تكامل API / POS معتمد</option>
                        </select>
                      </label>
                      <label>موافقة الفرع على طلب JIB
                        <select name="orderPermissionStatus" defaultValue={policy?.order_permission_status ?? "not_required"}>
                          <option value="not_required">غير مطلوبة للطريقة الحالية</option>
                          <option value="pending">بانتظار الموافقة</option>
                          <option value="approved">موافقة موثقة</option>
                          <option value="rejected">مرفوضة</option>
                          <option value="suspended">موقوفة</option>
                        </select>
                      </label>
                      <label>مرجع موافقة الفرع على طريقة الطلب (رقم الاتفاق / محضر / ملاحظة موثقة)
                        <input name="orderPermissionReference" type="text" maxLength={500} placeholder="مثال: موافقة مدير الفرع بتاريخ ..." defaultValue={policy?.order_permission_reference ?? ""} />
                      </label>
                      <label>الرابط الرسمي للطلب الرقمي (HTTPS)
                        <input name="orderChannelUrl" type="url" placeholder="https://..." defaultValue={policy?.order_channel_url ?? ""} />
                      </label>
                      <label>طريقة الولاء
                        <select name="loyaltyMode" defaultValue={policy?.loyalty_mode ?? "none"}>
                          <option value="none">لا يوجد / غير متاح</option>
                          <option value="jib_business_account">حساب ولاء تجاري خاص بـ JIB</option>
                          <option value="partner_business_account">حساب ولاء تجاري مشترك مع المتجر</option>
                          <option value="jib_rewards">مكافآت JIB الخاصة بنا</option>
                        </select>
                      </label>
                      <label>حالة موافقة برنامج الولاء الخارجي
                        <select name="loyaltyPermissionStatus" defaultValue={policy?.loyalty_permission_status ?? "not_required"}>
                          <option value="not_required">غير مطلوب</option>
                          <option value="pending">بانتظار الموافقة</option>
                          <option value="approved">موافقة موثقة</option>
                          <option value="rejected">مرفوضة</option>
                          <option value="suspended">موقوفة</option>
                        </select>
                      </label>
                      <label>مرجع موافقة برنامج الولاء الخارجي (رقم الاتفاق / محضر / ملاحظة موثقة)
                        <input name="loyaltyPermissionReference" type="text" maxLength={500} placeholder="مرجع موافقة البرنامج أو الفرع" defaultValue={policy?.loyalty_permission_reference ?? ""} />
                      </label>
                      <label>اسم برنامج الولاء
                        <input name="loyaltyProgramName" type="text" maxLength={120} placeholder="مثال: Club Carrefour" defaultValue={policy?.loyalty_program_name ?? ""} />
                      </label>
                    </div>
                    <label>ملاحظات تشغيلية داخلية (لا تتضمن كلمات مرور أو رموزاً سرية)
                      <textarea name="operatorNotes" rows={2} maxLength={1000} defaultValue={policy?.operator_notes ?? ""} />
                    </label>
                    {policyError ? <p className="error-state">إعدادات الفروع غير متاحة بعد. يلزم تطبيق ترحيل قاعدة البيانات أولاً؛ تم تعطيل الحفظ لتجنب فقدان الإعدادات.</p> :
                      <button className="branch-policy-save" type="submit">حفظ إعدادات هذا الفرع</button>}
                    <p className="branch-policy-hint">
                      حالة موافقة الطلب: {orderPermissionLabels[policy?.order_permission_status ?? "not_required"]} ·
                      موافقة الولاء: {loyaltyPermissionLabels[policy?.loyalty_permission_status ?? "not_required"]}
                    </p>
                  </form>
                </details>
              </td>
            </tr>;
          })}</tbody>
        </table></div>}
      {policyError ? <p className="error-state">تعذر قراءة إعدادات الفروع. غالباً لم يُطبّق ترحيل قاعدة البيانات على هذه البيئة بعد.</p> : null}
    </section>
  </main>;
}
