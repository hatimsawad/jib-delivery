import Link from "next/link";
import AdminHeader from "./admin-header";
import { requireAdmin } from "./admin-data";

export const dynamic = "force-dynamic";

type DashboardStore = {
  id: string; name: string; category: string; onboarding_status: string;
  is_active: boolean; is_open: boolean; created_at: string;
};
type DashboardOrder = {
  id: string; status: string; total_mad: number; created_at: string;
  stores: { name: string } | null;
};
const categoryLabels: Record<string, string> = { restaurant: "مطعم", grocery: "بقالة", shop: "متجر" };
const storeStatus = (status: string, active: boolean, open: boolean) => {
  if (status !== "approved") return status === "rejected" ? "مرفوض" : status === "suspended" ? "موقوف" : "بانتظار الاعتماد";
  return !active ? "معتمد · غير نشط" : open ? "مفتوح لاستقبال الطلبات" : "مغلق مؤقتاً";
};
const orderStatus: Record<string, string> = {
  pending: "طلب جديد", accepted: "مقبول", preparing: "قيد التحضير",
  ready_for_pickup: "جاهز للاستلام", picked_up: "تم الاستلام",
  delivering: "في الطريق", delivered: "تم التسليم", rejected: "مرفوض", cancelled: "ملغى",
};

export default async function Home() {
  const { supabase, user, profile } = await requireAdmin();
  const [allOrders, pendingOrders, activeStores, pendingStores, allStores, products, couriers, recentOrders, storeRows, brands] = await Promise.all([
    supabase.from("orders").select("id", { count: "exact", head: true }),
    supabase.from("orders").select("id", { count: "exact", head: true }).eq("status", "pending"),
    supabase.from("stores").select("id", { count: "exact", head: true }).eq("is_active", true).eq("onboarding_status", "approved"),
    supabase.from("stores").select("id", { count: "exact", head: true }).eq("onboarding_status", "pending"),
    supabase.from("stores").select("id", { count: "exact", head: true }),
    supabase.from("products").select("id", { count: "exact", head: true }),
    supabase.from("courier_profiles").select("user_id", { count: "exact", head: true }).eq("is_active", true),
    supabase.from("orders").select("id,status,total_mad,created_at,stores(name)").order("created_at", { ascending: false }).limit(7),
    supabase.from("stores").select("id,name,category,onboarding_status,is_active,is_open,created_at").order("created_at", { ascending: false }).limit(10),
    supabase.from("commercial_brands").select("id", { count: "exact", head: true }),
  ]);
  const errors = [allOrders,pendingOrders,activeStores,pendingStores,allStores,products,couriers,recentOrders,storeRows,brands].some(x => x.error);
  const dashboardStores = (storeRows.data ?? []) as DashboardStore[];
  const dashboardOrders = (recentOrders.data ?? []) as DashboardOrder[];
  const metrics = [
    {label:"المتاجر والمطاعم المسجلة",value:allStores.count ?? "—",note:"الفروع الحقيقية المسجلة",tone:"green"},
    {label:"بانتظار الاعتماد",value:pendingStores.count ?? "—",note:"طلبات الانضمام والمراجعة",tone:"gold"},
    {label:"الفروع النشطة",value:activeStores.count ?? "—",note:"معتمدة ومفتوحة",tone:"green"},
    {label:"الطلبات الجديدة",value:pendingOrders.count ?? "—",note:"تحتاج متابعة",tone:"red"},
  ];
  return <main className="shell manager-shell">
    <AdminHeader />
    <section className="manager-welcome manager-welcome-signature">
      <div><p className="eyebrow">JIB MANAGER · RABAT</p><h1>جيب وتكايس على JIB</h1>
      <p className="manager-tagline">كل شيء تحبه في مكان واحد</p>
      <p>مرحباً {profile?.full_name || user.email || "بك"} — مركز إدارة المتاجر والمطاعم والطلبات.</p></div>
      <div className="manager-welcome-actions"><Link href="/stores" className="primary-action">إدارة الفروع</Link><Link href="/brands" className="secondary-action">دليل العلامات التجارية</Link></div>
    </section>
    {errors && <p className="error-state">تعذر تحميل بعض البيانات. تحقق من اتصال قاعدة البيانات وصلاحيات القراءة.</p>}
    <section className="manager-metrics">
      {metrics.map((m)=><article className={`manager-metric metric-${m.tone}`} key={m.label}><span>{m.label}</span><b>{m.value}</b><small>{m.note}</small></article>)}
    </section>
    <section className="manager-catalog-strip">
      <div><span className="manager-catalog-icon">▦</span><div><strong>دليل العلامات والمتاجر المرشحة</strong><small>{brands.count ?? "—"} علامة مسجلة للتحضير والمراجعة، دون تفعيل فروع تلقائياً</small></div></div>
      <Link href="/brands">فتح الدليل ←</Link>
    </section>
    <section className="manager-columns manager-primary-columns">
      <div className="manager-section">
        <div className="manager-section-head"><div><p className="eyebrow">الشركاء والفروع</p><h2>المطاعم والمتاجر</h2></div><Link href="/stores">عرض الكل ←</Link></div>
        {storeRows.error ? <p className="error-state">تعذر قراءة قائمة المتاجر.</p> : dashboardStores.length === 0 ?
          <div className="manager-empty"><strong>لا توجد فروع حقيقية مسجلة بعد</strong><p>العلامات التجارية المحفوظة في الدليل لا تتحول تلقائياً إلى فروع. أضف الفرع الحقيقي ثم راجع وثائقه وحالة اعتماده.</p><Link href="/stores">فتح إدارة الفروع</Link></div> :
          <div className="manager-store-list">{dashboardStores.map((s)=><Link href="/stores" className="manager-store-row" key={s.id}>
            <span className="store-avatar">▣</span><span className="store-main"><strong>{s.name}</strong><small>{categoryLabels[s.category] ?? s.category}</small></span>
            <span className={`store-status ${s.onboarding_status==="approved" && s.is_active ? "is-approved" : "is-pending"}`}>{storeStatus(s.onboarding_status,s.is_active,s.is_open)}</span>
          </Link>)}</div>}
      </div>
      <div className="manager-section">
        <div className="manager-section-head"><div><p className="eyebrow">التشغيل اليومي</p><h2>أحدث الطلبات</h2></div><Link href="/orders">عرض الكل ←</Link></div>
        {recentOrders.error ? <p className="error-state">تعذر قراءة الطلبات.</p> : dashboardOrders.length === 0 ?
          <div className="manager-empty"><strong>لا توجد طلبات بعد</strong><p>ستظهر طلبات الزبائن وحالاتها هنا فور بدء التشغيل.</p></div> :
          <div className="manager-order-list">{dashboardOrders.map((o)=><Link href="/orders" className="manager-order-row" key={o.id}>
            <span className="order-dot"/><span className="order-main"><strong>{o.stores?.name ?? "طلب JIB"}</strong><small>#{String(o.id).slice(0,8)} · {new Date(o.created_at).toLocaleString("ar-MA")}</small></span>
            <span className="order-meta"><b>{o.total_mad} د.م</b><small>{orderStatus[o.status] ?? o.status}</small></span>
          </Link>)}</div>}
      </div>
    </section>
    <section className="manager-quick-links manager-secondary-tools">
      <Link href="/products"><strong>كتالوج المنتجات</strong><span>{products.count ?? "—"} منتج مسجل فعلياً</span></Link>
      <Link href="/users"><strong>المستخدمون والمندوبون</strong><span>{couriers.count ?? "—"} مندوب نشط</span></Link>
      <Link href="/tracking"><strong>تتبع المندوبين</strong><span>الموقع وحالة الاتصال</span></Link>
      <Link href="/brands"><strong>العلامات التجارية</strong><span>تحضير ومراجعة قبل التفعيل</span></Link>
    </section>
    <footer>JIB MANAGER © 2026 · الرباط، المغرب</footer>
  </main>;
}
