"use client";

import { useCallback, useEffect, useState } from "react";
import { createClient, type User } from "@supabase/supabase-js";

const supabase = createClient(
  "https://ldgbyshgcifheditplnn.supabase.co",
  "sb_publishable_wvNMRZTBFX4viI2ypcdWjQ_YBqgi_TV",
);

type Row = Record<string, unknown>;
type Stats = { orders: number; merchants: number; couriers: number; brands: number; products: number };

export default function AdminHome() {
  const [user, setUser] = useState<User | null>(null);
  const [authorized, setAuthorized] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [stats, setStats] = useState<Stats>({ orders: 0, merchants: 0, couriers: 0, brands: 0, products: 0 });
  const [orders, setOrders] = useState<Row[]>([]);
  const [couriers, setCouriers] = useState<Row[]>([]);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const loadDashboard = useCallback(async (currentUser: User) => {
    setBusy(true);
    setError("");
    try {
      const profile = await supabase.from("profiles").select("role").eq("id", currentUser.id).single();
      if (profile.error || profile.data?.role !== "admin") {
        await supabase.auth.signOut();
        setUser(null);
        setAuthorized(false);
        setError("هذا الحساب ليس حساب مدير JIB معتمداً.");
        return;
      }
      setAuthorized(true);
      const [orderCount, merchantCount, courierCount, brandCount, productCount, orderRows, courierRows] = await Promise.all([
        supabase.from("orders").select("id", { count: "exact", head: true }),
        supabase.from("merchants").select("id", { count: "exact", head: true }),
        supabase.from("courier_profiles").select("user_id", { count: "exact", head: true }),
        supabase.from("brands").select("id", { count: "exact", head: true }),
        supabase.from("products").select("id", { count: "exact", head: true }),
        supabase.from("orders").select("id,status,submitted_at,subtotal_mad,customer_phone,delivery_address,branches!inner(name)").order("submitted_at", { ascending: false }).limit(50),
        supabase.from("courier_profiles").select("user_id,is_on_duty,profiles!inner(full_name,phone)").eq("is_on_duty", true),
      ]);
      const failed = [orderRows, courierRows].find((result) => result.error);
      if (failed?.error) throw failed.error;
      setStats({
        orders: orderCount.count ?? 0,
        merchants: merchantCount.count ?? 0,
        couriers: courierCount.count ?? 0,
        brands: brandCount.count ?? 0,
        products: productCount.count ?? 0,
      });
      setOrders((orderRows.data ?? []) as Row[]);
      setCouriers((courierRows.data ?? []) as Row[]);
    } catch {
      setError("تعذر تحميل لوحة التشغيل. تحقق من إعدادات Data API وصلاحيات المدير.");
    } finally {
      setBusy(false);
    }
  }, []);

  useEffect(() => {
    let active = true;
    supabase.auth.getSession().then(({ data }) => {
      if (active && data.session?.user) {
        setUser(data.session.user);
        void loadDashboard(data.session.user);
      }
    });
    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!active) return;
      setUser(session?.user ?? null);
      if (session?.user) void loadDashboard(session.user);
      else { setAuthorized(false); setOrders([]); setCouriers([]); }
    });
    return () => { active = false; listener.subscription.unsubscribe(); };
  }, [loadDashboard]);

  async function signIn(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError("");
    const { data, error: authError } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
    if (authError) setError(authError.message);
    else if (data.user) {
      setUser(data.user);
      await loadDashboard(data.user);
    }
    setBusy(false);
  }

  async function dispatch(orderId: string, courierId: string) {
    setBusy(true);
    setError("");
    const { error: rpcError } = await supabase.rpc("admin_offer_courier", {
      p_order_id: orderId,
      p_courier_id: courierId,
    });
    if (rpcError) setError("لم يتم إرسال عرض التوصيل. تحقق من حالة الطلب والمندوب.");
    if (user) await loadDashboard(user);
    setBusy(false);
  }

  async function signOut() {
    await supabase.auth.signOut();
    setUser(null);
    setAuthorized(false);
  }

  const statusLabel = (status: unknown) => ({
    customer_submitted: "طلب جديد",
    merchant_accepted: "قبله المتجر",
    merchant_rejected: "مرفوض",
    preparing: "قيد التحضير",
    ready_for_pickup: "جاهز للمندوب",
    courier_offered: "عرض مرسل للمندوب",
    courier_accepted: "المندوب قبل",
    picked_up: "تم الاستلام",
    en_route: "في الطريق",
    delivered: "تم التسليم",
    cancelled: "ملغى",
  } as Record<string, string>)[String(status)] ?? String(status);

  if (!user || !authorized) {
    return (
      <main style={{ maxWidth: 440, margin: "8vh auto", padding: 24, background: "white", borderRadius: 18, border: "1px solid #e5e7eb" }}>
        <p style={{ color: "#64748b" }}>JIB V2 · مساحة تشغيل خاصة</p>
        <h1 style={{ fontSize: 28 }}>دخول الإدارة</h1>
        <p style={{ color: "#64748b" }}>الدخول متاح لحسابات الإدارة المعتمدة فقط.</p>
        <form onSubmit={signIn} style={{ display: "grid", gap: 12 }}>
          <input required type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="البريد الإلكتروني" style={fieldStyle} />
          <input required type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="كلمة المرور" style={fieldStyle} />
          <button disabled={busy} style={buttonStyle}>{busy ? "جارٍ الدخول..." : "تسجيل الدخول"}</button>
        </form>
        {error && <p style={{ color: "#b91c1c" }}>{error}</p>}
      </main>
    );
  }

  const tiles: [string, number][] = [
    ["الطلبات", stats.orders], ["التجار", stats.merchants], ["المندوبون", stats.couriers],
    ["العلامات", stats.brands], ["المنتجات", stats.products],
  ];

  return (
    <main style={{ maxWidth: 1180, margin: "0 auto", padding: 24 }}>
      <header style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 16, flexWrap: "wrap" }}>
        <div>
          <p style={{ color: "#64748b", marginBottom: 6 }}>JIB V2 · مساحة تشغيل داخلية</p>
          <h1 style={{ margin: 0, fontSize: 30 }}>لوحة الإدارة</h1>
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          <button onClick={() => user && loadDashboard(user)} style={secondaryButton}>تحديث</button>
          <button onClick={signOut} style={secondaryButton}>خروج</button>
        </div>
      </header>
      {error && <p style={{ color: "#b91c1c", background: "#fee2e2", padding: 12, borderRadius: 10 }}>{error}</p>}
      <section style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit,minmax(150px,1fr))", gap: 12, marginTop: 24 }}>
        {tiles.map(([label, value]) => <article key={label} style={tileStyle}>
          <p style={{ color: "#64748b", marginTop: 0 }}>{label}</p>
          <strong style={{ fontSize: 30 }}>{value}</strong>
        </article>)}
      </section>
      <section style={panelStyle}>
        <h2 style={{ marginTop: 0 }}>الطلبات ومراحل التنفيذ</h2>
        {orders.length === 0 && <p style={{ color: "#64748b" }}>لا توجد طلبات حتى الآن.</p>}
        {orders.map((order) => {
          const branch = order.branches as { name?: string } | undefined;
          return <article key={String(order.id)} style={{ borderTop: "1px solid #e5e7eb", padding: "14px 0" }}>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
              <strong>طلب #{String(order.id).slice(0, 8)} · {statusLabel(order.status)}</strong>
              <span>{String(order.subtotal_mad)} درهم</span>
            </div>
            <p style={{ margin: "6px 0", color: "#64748b" }}>{branch?.name ?? "الفرع"} · {String(order.customer_phone)} · {String(order.delivery_address)}</p>
            {order.status === "ready_for_pickup" && <div style={{ display: "flex", gap: 8, flexWrap: "wrap", alignItems: "center" }}>
              <span>إسناد إلى مندوب متاح:</span>
              {couriers.length === 0 && <span style={{ color: "#9a3412" }}>لا يوجد مندوب متاح الآن</span>}
              {couriers.map((courier) => {
                const profile = courier.profiles as { full_name?: string; phone?: string } | undefined;
                return <button key={String(courier.user_id)} disabled={busy} onClick={() => dispatch(String(order.id), String(courier.user_id))} style={secondaryButton}>
                  {profile?.full_name || profile?.phone || "مندوب"}
                </button>;
              })}
            </div>}
          </article>;
        })}
      </section>
      <section style={panelStyle}>
        <h2 style={{ marginTop: 0 }}>المندوبون المتاحون</h2>
        {couriers.length === 0 ? <p style={{ color: "#64748b" }}>لا يوجد مندوبون في وضع العمل حالياً.</p> : couriers.map((courier) => {
          const profile = courier.profiles as { full_name?: string; phone?: string } | undefined;
          return <p key={String(courier.user_id)}>{profile?.full_name || "مندوب"} — {profile?.phone || "بدون هاتف"}</p>;
        })}
      </section>
      {busy && <p style={{ color: "#64748b" }}>جارٍ تحديث البيانات...</p>}
    </main>
  );
}

const fieldStyle: React.CSSProperties = { width: "100%", boxSizing: "border-box", padding: 13, border: "1px solid #cbd5e1", borderRadius: 10, fontSize: 16 };
const buttonStyle: React.CSSProperties = { padding: "13px 16px", border: 0, borderRadius: 10, background: "#172554", color: "white", fontWeight: 700, cursor: "pointer" };
const secondaryButton: React.CSSProperties = { padding: "9px 12px", border: "1px solid #cbd5e1", borderRadius: 9, background: "white", color: "#172554", cursor: "pointer" };
const tileStyle: React.CSSProperties = { background: "white", border: "1px solid #e5e7eb", borderRadius: 14, padding: 16 };
const panelStyle: React.CSSProperties = { background: "white", border: "1px solid #e5e7eb", borderRadius: 16, padding: 20, marginTop: 18 };
