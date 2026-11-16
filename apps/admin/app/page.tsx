import Link from "next/link";
import AdminHeader from "./admin-header";
import { requireAdmin } from "./admin-data";

export const dynamic = "force-dynamic";

export default async function Home() {
  const { supabase, user, profile } = await requireAdmin();

  const [orders, stores, products, couriers] = await Promise.all([
    supabase.from("orders").select("id", { count: "exact", head: true }),
    supabase.from("stores").select("id", { count: "exact", head: true }).eq("is_active", true),
    supabase.from("products").select("id", { count: "exact", head: true }),
    supabase.from("courier_profiles").select("user_id", { count: "exact", head: true }).eq("is_active", true),
  ]);

  const metrics = [
    { label: "إجمالي الطلبات", value: orders.error ? "—" : String(orders.count ?? 0), note: "كل الطلبات المسجلة" },
    { label: "المتاجر النشطة", value: stores.error ? "—" : String(stores.count ?? 0), note: "المتاجر المعتمدة" },
    { label: "المنتجات", value: products.error ? "—" : String(products.count ?? 0), note: "الأصناف المسجلة" },
    { label: "السائقون", value: couriers.error ? "—" : String(couriers.count ?? 0), note: "السائقون المعتمدون" },
  ];

  const shortcuts = [
    { href: "/orders", icon: "↗", title: "الطلبات", description: "متابعة حالات الطلبات والدفع" },
    { href: "/stores", icon: "▣", title: "المتاجر", description: "مراجعة المتاجر النشطة والمغلقة" },
    { href: "/products", icon: "◇", title: "المنتجات", description: "متابعة الأسعار والتوفر" },
    { href: "/users", icon: "♙", title: "المستخدمون", description: "مراجعة حسابات الزبائن والسائقين والتجار" },
  ];

  return (
    <main className="shell">
      <AdminHeader />
      <section className="hero">
        <p className="eyebrow">لوحة التحكم المركزية</p>
        <h1>كلشي قريب ليك.</h1>
        <p>مرحباً {profile?.full_name || user.email || "بك"}، هذه نظرة مباشرة على بيانات منصة JIB.</p>
      </section>
      <section className="metrics">
        {metrics.map((metric) => (
          <article className="metric" key={metric.label}>
            <span>{metric.label}</span><b>{metric.value}</b><small>{metric.note}</small>
          </article>
        ))}
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
      <footer>JIB © 2026 · الرباط، المغرب</footer>
    </main>
  );
}
