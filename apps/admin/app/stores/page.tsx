import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";
import { setStoreStatus } from "./actions";

type StoreRow = {
  id: string; name: string; category: string; phone: string | null;
  address_text: string | null; is_active: boolean; is_open: boolean; created_at: string;
};

export const dynamic = "force-dynamic";

export default async function StoresPage() {
  const { supabase } = await requireAdmin();
  const { data, error } = await supabase.from("stores")
    .select("id,name,category,phone,address_text,is_active,is_open,created_at")
    .order("created_at", { ascending: false }).limit(100);
  const stores = (data ?? []) as unknown as StoreRow[];
  const categories: Record<string, string> = { restaurant: "مطعم", grocery: "بقالة", shop: "متجر" };

  return <main className="shell">
    <AdminHeader />
    <section className="page-heading"><p className="eyebrow">الشركاء المحليون</p><h1>المتاجر</h1><p>مراجعة المتاجر المسجلة واعتمادها قبل ظهورها للزبائن.</p></section>
    <section className="list-panel">
      <div className="section-heading"><h2>قائمة المتاجر</h2><span className="count-chip">{stores.length} متجر</span></div>
      {error ? <p className="error-state">تعذر تحميل المتاجر. تحقق من صلاحيات قاعدة البيانات.</p> :
        stores.length === 0 ? <div className="empty-state"><strong>لم تتم إضافة متاجر بعد</strong><span>يمكن للتجار إنشاء حساباتهم، وستظهر طلبات متاجرهم هنا لاعتمادها.</span></div> :
        <div className="table-wrap"><table><thead><tr><th>المتجر</th><th>الفئة</th><th>العنوان</th><th>الهاتف</th><th>الحالة</th><th>الإجراء</th></tr></thead>
          <tbody>{stores.map(store => <tr key={store.id}>
            <td><strong>{store.name}</strong></td><td>{categories[store.category] ?? store.category}</td>
            <td>{store.address_text || "—"}</td><td>{store.phone || "—"}</td>
            <td><span className={store.is_active ? "status-pill status-good" : "status-pill"}>{store.is_active ? (store.is_open ? "نشط ومفتوح" : "نشط ومغلق") : "بانتظار الاعتماد"}</span></td>
            <td><form action={setStoreStatus}>
              <input type="hidden" name="storeId" value={store.id} />
              <input type="hidden" name="isActive" value={String(!store.is_active)} />
              <button className="logout-button inline-action" type="submit">{store.is_active ? "إلغاء الاعتماد" : "اعتماد وفتح المتجر"}</button>
            </form></td>
          </tr>)}</tbody>
        </table></div>}
    </section>
  </main>;
}
