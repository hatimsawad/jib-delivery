import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";

type OrderRow = {
  id: string; status: string; payment_method: string; payment_status: string;
  subtotal_mad: number; delivery_fee_mad: number; total_mad: number; created_at: string;
};

const statusLabels: Record<string, string> = {
  pending: "بانتظار التأكيد", accepted: "مقبول", rejected: "مرفوض",
  preparing: "قيد التحضير", ready_for_pickup: "جاهز للاستلام",
  picked_up: "تم الاستلام", delivering: "قيد التوصيل",
  delivered: "تم التسليم", cancelled: "ملغى",
};

export const dynamic = "force-dynamic";

export default async function OrdersPage() {
  const { supabase } = await requireAdmin();
  const { data, error } = await supabase.from("orders")
    .select("id,status,payment_method,payment_status,subtotal_mad,delivery_fee_mad,total_mad,created_at")
    .order("created_at", { ascending: false }).limit(100);
  const orders = (data ?? []) as unknown as OrderRow[];

  return <main className="shell">
    <AdminHeader />
    <section className="page-heading"><p className="eyebrow">مراقبة العمليات</p><h1>الطلبات</h1><p>آخر 100 طلب مسجل في منصة JIB، مع حالة الدفع والتوصيل.</p></section>
    <section className="list-panel">
      <div className="section-heading"><h2>سجل الطلبات</h2><span className="count-chip">{orders.length} طلب</span></div>
      {error ? <p className="error-state">تعذر تحميل الطلبات. تحقق من اتصال قاعدة البيانات وسياسات الوصول.</p> :
        orders.length === 0 ? <div className="empty-state"><strong>لا توجد طلبات بعد</strong><span>ستظهر الطلبات هنا فور تنفيذ أول طلب حقيقي من تطبيق JIB.</span></div> :
        <div className="table-wrap"><table>
          <thead><tr><th>رقم الطلب</th><th>الحالة</th><th>الدفع</th><th>المجموع</th><th>التاريخ</th></tr></thead>
          <tbody>{orders.map(order => <tr key={order.id}>
            <td className="mono">#{order.id.slice(0,8)}</td>
            <td><span className="status-pill">{statusLabels[order.status] ?? order.status}</span></td>
            <td>{order.payment_method === "cash" ? "نقداً عند التسليم" : order.payment_method} · {order.payment_status === "paid" ? "مدفوع" : "غير مدفوع"}</td>
            <td className="amount">{Number(order.total_mad).toFixed(2)} د.م.</td>
            <td>{new Date(order.created_at).toLocaleString("ar-MA")}</td>
          </tr>)}</tbody>
        </table></div>}
    </section>
  </main>;
}
