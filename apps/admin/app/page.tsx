import Link from "next/link";
import AdminHeader from "./admin-header";
import { requireAdmin } from "./admin-data";

export const dynamic = "force-dynamic";

export default async function Home() {
  const { supabase, user, profile } = await requireAdmin();

  const [allOrders, pending, preparing, delivery, stores, products, couriers] = await Promise.all([
    supabase.from("orders").select("id", { count: "exact", head: true }),
    supabase.from("orders").select("id", { count: "exact", head: true }).eq("status", "pending"),
    supabase.from("orders").select("id", { count: "exact", head: true }).in("status", ["accepted", "preparing", "ready_for_pickup"]),
    supabase.from("orders").select("id", { count: "exact", head: true }).in("status", ["picked_up", "delivering"]),
    supabase.from("stores").select("id", { count: "exact", head: true }).eq("is_active", true),
    supabase.from("products").select("id", { count: "exact", head: true }),
    supabase.from("courier_profiles").select("user_id", { count: "exact", head: true }).eq("is_active", true),
  ]);

  const hasReadError = [allOrders, pending, preparing, delivery, stores, products, couriers].some((item) => item.error);
  const metrics = [
    { label: "إجمالي الطلبات", value: allOrders.count, note: "كل الطلبات المسجلة" },
    { label: "طلبات جديدة", value: pending.count, note: "تحتاج متابعة التاجر" },
    { label: "قيد التحضير", value: preparing.count, note: "لدى المتاجر" },
    { label: "في الطريق", value: delivery.count, note: "توصيلات نشطة" },
    { label: "المتاجر النشطة", value: stores.count, note: "الشركاء المعتمدون" },
    { label: "المنتجات", value: products.count, note: "الأصناف المسجلة" },
    { label: "المندوبون", value: couriers.count, note: "المندوبون المعتمدون" },
  ];

  const shortcuts = [
    { href: "/orders", icon: "↗", title: "مراقبة الطلبات", description: "الحالات والدفع وسجل العمليات" },
    { href: "/stores", icon: "▣", title: "إدارة المتاجر", description: "اعتماد الشركاء ومراجعة النشاط" },
    { href: "/products", icon: "◇", title: "كتالوج المنتجات", description: "الأسعار والتوفر" },
    { href: "/users", icon: "♙", title: "الحسابات والمندوبون", description: "المستخدمون وطلبات الاعتماد" },
    { href: "/images", icon: "✦", title: "استوديو الصور الذكي", description: "توليد صور المنتجات والمقالات ومراجعتها" },
  ];

  return (
    <main className="shell">
      <AdminHeader />
      <section className="hero">
        <p className="eyebrow">JIB MANAGER · مركز القيادة والتشغيل</p>
        <h1>كل عمليات JIB، في مكان واحد.</h1>
        <p>مرحباً {profile?.full_name || user.email || "بك"}، هذه قراءة مباشرة لمؤشرات المنصة من قاعدة البيانات.</p>
      </section>
      {hasReadError && <p className="error-state">تعذر تحميل مؤشر واحد أو أكثر. لا تعتبر الأرقام المعروضة حالة تشغيل مكتملة؛ راجع اتصال Supabase وسياسات الوصول.</p>}
      <section className="metrics">
        {metrics.map((metric) => (
          <article className="metric" key={metric.label}>
            <span>{metric.label}</span><b>{metric.value ?? "—"}</b><small>{metric.note}</small>
          </article>
        ))}
      </section>
      <section className="manager-notice">
        <div><strong>حالة مركز الإدارة</strong><p>المصادقة الإدارية مفعلة. بيانات المؤشرات تُقرأ مباشرة عند فتح الصفحة.</p></div>
        <span className={hasReadError ? "status-pill" : "status-pill status-good"}>{hasReadError ? "توجد أخطاء قراءة" : "اتصال قاعدة البيانات سليم"}</span>
      </section>
      <section className="shortcut-grid">
        {shortcuts.map((shortcut) => (
          <Link href={shortcut.href} className="shortcut-card" key={shortcut.href}>
            <span className="shortcut-icon">{shortcut.icon}</span>
            <strong>{shortcut.title}</strong>
            <span>{shortcut.description}</span>
            <small>فتح القسم ←</small>
          </Link>
        ))}
      </section>
      <footer>JIB MANAGER © 2026 · الرباط، المغرب</footer>
    </main>
  );
}
