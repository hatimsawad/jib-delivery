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

const categoryLabels: Record<string, string> = {
  restaurant: "مطعم", grocery: "بقالة", shop: "متجر",
};
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
  const [allOrders, pendingOrders, activeStores, pendingStores, allStores, products, couriers, recentOrders, storeRows] = await Promise.all([
    supabase.from("orders").select("id", { count: "exact", head: true }),
    supabase.from("orders").select("id", { count: "exact", head: true }).eq("status", "pending"),
    supabase.from("stores").select("id", { count: "exact", head: true }).eq("is_active", true).eq("onboarding_status", "approved"),
    supabase.from("stores").select("id", { count: "exact", head: true }).eq("onboarding_status", "pending"),
    supabase.from("stores").select("id", { count: "exact", head: true }),
    supabase.from("products").select("id", { count: "exact", head: true }),
    supabase.from("courier_profiles").select("user_id", { count: "exact", head: true }).eq("is_active", true),
    supabase.from("orders").select("id,status,total_mad,created_at,stores(name)").order("created_at", { ascending: false }).limit(6),
    supabase.from("stores").select("id,name,category,onboarding_status,is_active,is_open,created_at").order("created_at", { ascending: false }).limit(8),
  ]);
  const errors = [allOrders,pendingOrders,activeStores,pendingStores,allStores,products,couriers,recentOrders,storeRows].some(x => x.error);
  const dashboardStores = (storeRows.data ?? []) as DashboardStore[];
  const dashboardOrders = (recentOrders.data ?? []) as DashboardOrder[];
  const metrics = [
    {label:"المتاجر والمطاعم",value:allStores.count ?? "—",note:"كل الفروع المسجلة",tone:"green"},
    {label:"تنتظر الاعتماد",value:pendingStores.count ?? "—",note:"طلبات انضمام تحتاج مراجعة",tone:"gold"},
    {label:"المتاجر المعتمدة",value:activeStores.count ?? "—",note:"الفروع النشطة",tone:"green"},
    {label:"الطلبات الجديدة",value:pendingOrders.count ?? "—",note:"تحتاج متابعة فورية",tone:"red"},
  ];
  return <main className="shell manager-shell">
    <AdminHeader />
    <section className="manager-welcome">
      <div><p className="eyebrow">JIB MANAGER · الرباط</p><h1>مرحباً {profile?.full_name || user.email || "بك"}</h1>
      <p>مركز تشغيل جيب: المتاجر والمطاعم والطلبات في الواجهة.</p></div>
      <Link href="/stores" className="primary-action">إدارة المتاجر والفروع ←</Link>
    </section>
    {errors && <p className="error-state">تعذر تحميل بعض البيانات. تحقق من اتصال قاعدة البيانات وصلاحيات القراءة.</p>}
    <section className="manager-metrics">
      {metrics.map((m)=><article className={`manager-metric metric-${m.tone}`} key={m.label}><span>{m.label}</span><b>{m.value}</b><small>{m.note}</small></article>)}
    </section>
    <section className="manager-columns">
      <div className="manager-section">
        <div className="manager-section-head"><div><p className="eyebrow">الشركاء</p><h2>المطاعم والمتاجر</h2></div><Link href="/stores">عرض الكل ←</Link></div>
        {storeRows.error ? <p className="error-state">تعذر قراءة قائمة المتاجر.</p> : dashboardStores.length === 0 ?
          <div className="manager-empty"><strong>لا توجد متاجر مسجلة بعد</strong><p>ستظهر هنا طلبات انضمام المطاعم والمتاجر فور تسجيلها.</p><Link href="/stores">فتح إدارة المتاجر</Link></div> :
          <div className="manager-store-list">{dashboardStores.map((s)=><Link href="/stores" className="manager-store-row" key={s.id}>
            <span className="store-avatar">▣</span><span className="store-main"><strong>{s.name}</strong><small>{categoryLabels[s.category] ?? s.category}</small></span>
            <span className={`store-status ${s.onboarding_status==="approved" && s.is_active ? "is-approved" : "is-pending"}`}>{storeStatus(s.onboarding_status,s.is_active,s.is_open)}</span>
          </Link>)}</div>}
      </div>
      <div className="manager-section">
        <div className="manager-section-head"><div><p className="eyebrow">التشغيل اليومي</p><h2>أحدث الطلبات</h2></div><Link href="/orders">عرض الكل ←</Link></div>
        {recentOrders.error ? <p className="error-state">تعذر قراءة الطلبات.</p> : dashboardOrders.length === 0 ?
          <div className="manager-empty"><strong>لا توجد طلبات بعد</strong><p>ستظهر طلبات الزبائن وحالاتها هنا.</p></div> :
          <div className="manager-order-list">{dashboardOrders.map((o)=><Link href="/orders" className="manager-order-row" key={o.id}>
            <span className="order-dot"/><span className="order-main"><strong>{o.stores?.name ?? "طلب JIB"}</strong><small>#{String(o.id).slice(0,8)} · {new Date(o.created_at).toLocaleString("ar-MA")}</small></span>
            <span className="order-meta"><b>{o.total_mad} د.م</b><small>{orderStatus[o.status] ?? o.status}</small></span>
          </Link>)}</div>}
      </div>
    </section>
    <section className="manager-quick-links">
      <Link href="/products"><strong>المنتجات</strong><span>{products.count ?? "—"} صنف مسجل</span></Link>
      <Link href="/users"><strong>المستخدمون والمندوبون</strong><span>{couriers.count ?? "—"} مندوب نشط</span></Link>
      <Link href="/tracking"><strong>تتبع المندوبين</strong><span>الموقع وحالة الاتصال</span></Link>
    </section>
    <footer>JIB MANAGER © 2026 · الرباط، المغرب</footer>
  </main>;
}
