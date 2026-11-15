import { redirect } from "next/navigation";
import { createClient } from "../lib/supabase/server";
import LogoutButton from "./logout-button";

export const dynamic = "force-dynamic";

export default async function Home() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profileData } = await supabase.from("profiles").select("full_name, role").eq("id", user.id).maybeSingle();
  const profile = profileData as { full_name: string | null; role: string } | null;
  if (profile?.role !== "admin") {
    return <main className="shell"><header className="topbar"><div className="brand"><span className="mark">J</span><div><strong>جيب JIB</strong><small>لوحة الإدارة</small></div></div><LogoutButton /></header><section className="access-denied"><h1>لا تملك صلاحية الدخول</h1><p>هذا الحساب غير مسجل كمدير لمنصة JIB. تواصل مع مسؤول النظام لمنح الصلاحية.</p></section></main>;
  }

  const [orders, stores, couriers] = await Promise.all([
    supabase.from("orders").select("id", { count: "exact", head: true }),
    supabase.from("stores").select("id", { count: "exact", head: true }).eq("is_active", true),
    supabase.from("profiles").select("id", { count: "exact", head: true }).eq("role", "courier"),
  ]);
  const metrics = [
    { label: "إجمالي الطلبات", value: orders.error ? "—" : String(orders.count ?? 0), note: "كل الطلبات المسجلة" },
    { label: "المتاجر النشطة", value: stores.error ? "—" : String(stores.count ?? 0), note: "المتاجر المعتمدة" },
    { label: "حسابات السائقين", value: couriers.error ? "—" : String(couriers.count ?? 0), note: "السائقون المسجلون" },
    { label: "حالة الربط", value: "متصل", note: "Supabase · جلسة مدير" },
  ];

  return <main className="shell">
    <header className="topbar"><div className="brand"><span className="mark">J</span><div><strong>جيب JIB</strong><small>منصة التوصيل · الرباط</small></div></div><div className="top-actions"><span className="status">مدير موثّق</span><LogoutButton /></div></header>
    <section className="hero"><p className="eyebrow">لوحة التحكم المركزية</p><h1>كلشي قريب ليك.</h1><p>مرحباً {profile.full_name || user.email}، هذه نظرة عامة على منصة JIB.</p></section>
    <section className="metrics">{metrics.map((m) => <article className="metric" key={m.label}><span>{m.label}</span><b>{m.value}</b><small>{m.note}</small></article>)}</section>
    <section className="panel"><div><h2>إدارة المنصة</h2><p>تم تفعيل التحقق من هوية المدير. ستظهر البيانات حسب الصلاحيات الممنوحة لهذا الحساب.</p></div><ul><li>الطلبات ومتابعة حالتها</li><li>مراجعة المتاجر والمنتجات</li><li>حسابات السائقين والمستخدمين</li><li>مؤشرات الأداء والتقارير</li></ul></section>
    <footer>JIB © 2026 · الرباط، المغرب</footer>
  </main>;
}
