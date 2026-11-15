import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";

type ProductRow = {
  id: string; name: string; description: string | null; price_mad: number;
  store_id: string; is_available: boolean; created_at: string;
};

export const dynamic = "force-dynamic";

export default async function ProductsPage() {
  const { supabase } = await requireAdmin();
  const { data, error } = await supabase.from("products")
    .select("id,name,description,price_mad,store_id,is_available,created_at")
    .order("created_at", { ascending: false }).limit(100);
  const products = (data ?? []) as unknown as ProductRow[];

  return <main className="shell">
    <AdminHeader />
    <section className="page-heading"><p className="eyebrow">كتالوج JIB</p><h1>المنتجات</h1><p>عرض المنتجات وأسعارها وتوفرها لدى المتاجر.</p></section>
    <section className="list-panel">
      <div className="section-heading"><h2>قائمة المنتجات</h2><span className="count-chip">{products.length} منتج</span></div>
      {error ? <p className="error-state">تعذر تحميل المنتجات. تحقق من صلاحيات قاعدة البيانات.</p> :
        products.length === 0 ? <div className="empty-state"><strong>لا توجد منتجات بعد</strong><span>ستظهر المنتجات عند تسجيل المتاجر وإضافة أصنافها.</span></div> :
        <div className="table-wrap"><table><thead><tr><th>المنتج</th><th>وصف مختصر</th><th>المتجر</th><th>السعر</th><th>التوفر</th></tr></thead>
          <tbody>{products.map(product => <tr key={product.id}>
            <td><strong>{product.name}</strong></td><td>{product.description || "—"}</td>
            <td className="mono">{product.store_id.slice(0,8)}</td><td className="amount">{Number(product.price_mad).toFixed(2)} د.م.</td>
            <td><span className={product.is_available ? "status-pill status-good" : "status-pill"}>{product.is_available ? "متاح" : "غير متاح"}</span></td>
          </tr>)}</tbody>
        </table></div>}
    </section>
  </main>;
}
