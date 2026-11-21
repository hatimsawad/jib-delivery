"use client";

import { useCallback, useEffect, useState, type CSSProperties, type FormEvent } from "react";
import { createClient, type User } from "@supabase/supabase-js";

const OWNER_EMAIL = "hatilswad@gmail.com";
const supabase = createClient(
  "https://ldgbyshgcifheditplnn.supabase.co",
  "sb_publishable_wvNMRZTBFX4viI2ypcdWjQ_YBqgi_TV",
);

type Row = Record<string, unknown>;
type Stats = { orders: number; merchants: number; couriers: number; brands: number; products: number };

export default function AdminHome() {
  const [user, setUser] = useState<User | null>(null);
  const [authorized, setAuthorized] = useState(false);
  const [email, setEmail] = useState(OWNER_EMAIL);
  const [fullName, setFullName] = useState("");
  const [registerMode, setRegisterMode] = useState(false);
  const [password, setPassword] = useState("");
  const [stats, setStats] = useState<Stats>({ orders: 0, merchants: 0, couriers: 0, brands: 0, products: 0 });
  const [orders, setOrders] = useState<Row[]>([]);
  const [couriers, setCouriers] = useState<Row[]>([]);
  const [profiles, setProfiles] = useState<Row[]>([]);
  const [merchants, setMerchants] = useState<Row[]>([]);
  const [branches, setBranches] = useState<Row[]>([]);
  const [selectedProfileId, setSelectedProfileId] = useState("");
  const [onboardRole, setOnboardRole] = useState<"merchant" | "courier">("merchant");
  const [businessName, setBusinessName] = useState("");
  const [businessPhone, setBusinessPhone] = useState("");
  const [selectedMerchantId, setSelectedMerchantId] = useState("");
  const [branchName, setBranchName] = useState("");
  const [branchAddress, setBranchAddress] = useState("");
  const [branchCity, setBranchCity] = useState("Rabat");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const loadDashboard = useCallback(async (currentUser: User) => {
    setBusy(true);
    setError("");
    try {
      const profile = await supabase.from("profiles").select("role").eq("id", currentUser.id).single();
      let currentRole = profile.data?.role;
      if (currentRole !== "admin" && currentUser.email?.toLowerCase() === OWNER_EMAIL) {
        const { error: bootstrapError } = await supabase.rpc("bootstrap_owner_admin");
        if (!bootstrapError) {
          const refreshed = await supabase.from("profiles").select("role").eq("id", currentUser.id).single();
          currentRole = refreshed.data?.role;
        }
      }
      if (profile.error || currentRole !== "admin") {
        await supabase.auth.signOut();
        setUser(null);
        setAuthorized(false);
        setError("هذا الحساب غير معتمد كمدير JIB. استخدم بريد المالك المعتمد لإنشاء حساب الإدارة لأول مرة.");
        return;
      }
      setAuthorized(true);
      const [orderCount, merchantCount, courierCount, brandCount, productCount, orderRows, courierRows, profileRows, merchantRows, branchRows] = await Promise.all([
        supabase.from("orders").select("id", { count: "exact", head: true }),
        supabase.from("merchants").select("id", { count: "exact", head: true }),
        supabase.from("courier_profiles").select("user_id", { count: "exact", head: true }),
        supabase.from("brands").select("id", { count: "exact", head: true }),
        supabase.from("products").select("id", { count: "exact", head: true }),
        supabase.from("orders").select("id,status,submitted_at,subtotal_mad,customer_phone,delivery_address,branches!inner(name)").order("submitted_at", { ascending: false }).limit(50),
        supabase.from("courier_profiles").select("user_id,is_on_duty,profiles!inner(full_name,phone)").eq("is_on_duty", true),
        supabase.from("profiles").select("id,email,full_name,phone,role").order("created_at", { ascending: false }).limit(100),
        supabase.from("merchants").select("id,name,owner_user_id,is_active").order("name"),
        supabase.from("branches").select("id,name,address,city,is_active,merchant_id,merchants(name)").order("name"),
      ]);
      const failed = [orderRows, courierRows, profileRows, merchantRows, branchRows].find((result) => result.error);
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
      setProfiles((profileRows.data ?? []) as Row[]);
      setMerchants((merchantRows.data ?? []) as Row[]);
      setBranches((branchRows.data ?? []) as Row[]);
      if (!selectedMerchantId && merchantRows.data?.length) setSelectedMerchantId(merchantRows.data[0].id);
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

  async function registerOwner(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (email.trim().toLowerCase() !== OWNER_EMAIL) {
      setError("إنشاء حساب الإدارة الأول متاح فقط لبريد مالك JIB المعتمد.");
      return;
    }
    if (password.length < 8) {
      setError("كلمة المرور يجب أن تتكون من 8 أحرف على الأقل.");
      return;
    }
    setBusy(true);
    setError("");
    const { data, error: authError } = await supabase.auth.signUp({
      email: OWNER_EMAIL,
      password,
      options: { data: { full_name: fullName.trim() } },
    });
    if (authError) {
      setError(authError.message);
    } else if (data.session && data.user) {
      await loadDashboard(data.user);
    } else {
      setError("تم إنشاء الحساب. افتح رسالة تأكيد البريد الإلكتروني، ثم ارجع إلى هنا وسجّل الدخول بنفس البريد وكلمة المرور. لن يُمنح دور المدير قبل تأكيد البريد.");
    }
    setBusy(false);
  }

  async function signIn(event: FormEvent<HTMLFormElement>) {
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

  async function onboardUser() {
    if (!user || !selectedProfileId) { setError("اختر حساباً أولاً."); return; }
    setBusy(true); setError("");
    const { error: rpcError } = await supabase.rpc("admin_onboard_user", {
      p_user_id: selectedProfileId,
      p_role: onboardRole,
      p_business_name: onboardRole === "merchant" ? businessName.trim() : null,
      p_phone: businessPhone.trim() || null,
    });
    if (rpcError) setError("تعذر اعتماد الحساب. تحقق من الاسم والصلاحيات.");
    else { setBusinessName(""); setBusinessPhone(""); }
    await loadDashboard(user);
    setBusy(false);
  }

  async function createBranch() {
    if (!user || !selectedMerchantId) { setError("اختر تاجراً أولاً."); return; }
    setBusy(true); setError("");
    const { error: rpcError } = await supabase.rpc("admin_create_branch", {
      p_merchant_id: selectedMerchantId,
      p_name: branchName.trim(),
      p_address: branchAddress.trim(),
      p_city: branchCity.trim() || "Rabat",
    });
    if (rpcError) setError("تعذر إنشاء الفرع. تحقق من البيانات.");
    else { setBranchName(""); setBranchAddress(""); }
    await loadDashboard(user);
    setBusy(false);
  }

  async function setBranchActive(branchId: string, active: boolean) {
    if (!user) return;
    setBusy(true); setError("");
    const { error: rpcError } = await supabase.rpc("admin_set_branch_active", {
      p_branch_id: branchId, p_active: active,
    });
    if (rpcError) setError("تعذر تغيير حالة الفرع.");
    await loadDashboard(user);
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
      <main style={loginShellStyle}>
        <section style={loginCardStyle}>
          <div style={brandMarkStyle}><span style={{ color: "#D8BC79" }}>J</span><span style={{ color: "#FFFFFF" }}>IB</span></div>
          <p style={{ color: "#B9C7BE", margin: "0 0 8px", letterSpacing: 2, fontSize: 12 }}>JIB · RABAT · MOROCCO</p>
          <h1 style={{ fontSize: 28, color: "#FFFFFF", margin: "0 0 8px" }}>{registerMode ? "تفعيل حساب المالك" : "مركز قيادة JIB"}</h1>
          <p style={{ color: "#D2DAD4", lineHeight: 1.8, marginTop: 0 }}>{registerMode ? "أنشئ حساب الإدارة الأول بالبريد المعتمد. لا يمكن لأي بريد آخر الحصول على صلاحية المالك." : "إدارة الطلبات والتجار والفروع والمنتجات والتوصيل من مكان واحد."}</p>
          {registerMode ? (
            <form onSubmit={registerOwner} style={{ display: "grid", gap: 12 }}>
              <input required value={fullName} onChange={(e) => setFullName(e.target.value)} placeholder="الاسم الكامل" style={fieldStyle} />
              <input required type="email" value={OWNER_EMAIL} readOnly style={{ ...fieldStyle, background: "#F0F0EA", color: "#34463B" }} />
              <input required minLength={8} type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="أنشئ كلمة مرور جديدة (8 أحرف على الأقل)" style={fieldStyle} />
              <button disabled={busy} style={buttonStyle}>{busy ? "جارٍ إنشاء الحساب..." : "إنشاء حساب المالك"}</button>
              <button type="button" onClick={() => { setRegisterMode(false); setError(""); }} style={secondaryButton}>العودة إلى تسجيل الدخول</button>
            </form>
          ) : (
            <form onSubmit={signIn} style={{ display: "grid", gap: 12 }}>
              <input required type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="البريد الإلكتروني" style={fieldStyle} />
              <input required type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="كلمة المرور" style={fieldStyle} />
              <button disabled={busy} style={buttonStyle}>{busy ? "جارٍ الدخول..." : "تسجيل الدخول"}</button>
              <button type="button" onClick={() => { setRegisterMode(true); setEmail(OWNER_EMAIL); setError(""); }} style={secondaryButton}>إنشاء / تفعيل حساب المالك لأول مرة</button>
            </form>
          )}
          {error && <p style={authMessageStyle}>{error}</p>}
          <p style={{ color: "#AEBBB2", fontSize: 12, marginTop: 18 }}>وصول محمي · صلاحية المالك مرتبطة ببريد موثّق محدد</p>
        </section>
      </main>
    );
  }

  const tiles: [string, number][] = [
    ["الطلبات", stats.orders], ["التجار", stats.merchants], ["المندوبون", stats.couriers],
    ["العلامات", stats.brands], ["المنتجات", stats.products],
  ];

  return (
    <main style={{ maxWidth: 1180, margin: "0 auto", padding: 24 }}>
      <header style={dashboardHeaderStyle}>
        <div>
          <div style={brandMarkSmallStyle}><span style={{ color: "#D8BC79" }}>J</span><span style={{ color: "#FFFFFF" }}>IB</span></div>
          <p style={{ color: "#D2DAD4", margin: "8px 0 6px" }}>JIB V2 · مساحة تشغيل داخلية</p>
          <h1 style={{ margin: 0, fontSize: 30, color: "#FFFFFF" }}>لوحة قيادة جيب</h1>
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
        <h2 style={{ marginTop: 0 }}>اعتماد حساب تاجر أو مندوب</h2>
        <p style={{ color: "#64748b" }}>يسجل الشخص حسابه أولاً من تطبيق JIB، ثم تختار حسابه هنا لاعتماده.</p>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit,minmax(220px,1fr))", gap: 10 }}>
          <select value={selectedProfileId} onChange={(e) => setSelectedProfileId(e.target.value)} style={fieldStyle}>
            <option value="">اختر حساباً مسجلاً</option>
            {profiles.filter((p) => p.role === "customer").map((p) => (
              <option key={String(p.id)} value={String(p.id)}>{String(p.full_name || p.email || p.phone || p.id)}</option>
            ))}
          </select>
          <select value={onboardRole} onChange={(e) => setOnboardRole(e.target.value as "merchant" | "courier")} style={fieldStyle}>
            <option value="merchant">تاجر</option>
            <option value="courier">مندوب توصيل</option>
          </select>
          {onboardRole === "merchant" && <input value={businessName} onChange={(e) => setBusinessName(e.target.value)} placeholder="اسم المتجر" style={fieldStyle} />}
          <input value={businessPhone} onChange={(e) => setBusinessPhone(e.target.value)} placeholder="رقم الهاتف" style={fieldStyle} />
        </div>
        <button disabled={busy || !selectedProfileId} onClick={onboardUser} style={{ ...buttonStyle, marginTop: 12 }}>اعتماد الحساب</button>
        <p style={{ color: "#64748b", fontSize: 13 }}>اعتماد المندوب ينشئ ملف المندوب مع إيقاف التوفر افتراضياً. اعتماد التاجر ينشئ سجله غير النشط حتى إضافة فرع ومراجعته.</p>
      </section>
      <section style={panelStyle}>
        <h2 style={{ marginTop: 0 }}>إنشاء فرع للمتجر</h2>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit,minmax(200px,1fr))", gap: 10 }}>
          <select value={selectedMerchantId} onChange={(e) => setSelectedMerchantId(e.target.value)} style={fieldStyle}>
            <option value="">اختر المتجر</option>
            {merchants.map((m) => <option key={String(m.id)} value={String(m.id)}>{String(m.name)}{m.is_active ? "" : " — غير نشط"}</option>)}
          </select>
          <input value={branchName} onChange={(e) => setBranchName(e.target.value)} placeholder="اسم الفرع" style={fieldStyle} />
          <input value={branchAddress} onChange={(e) => setBranchAddress(e.target.value)} placeholder="عنوان الفرع" style={fieldStyle} />
          <input value={branchCity} onChange={(e) => setBranchCity(e.target.value)} placeholder="المدينة" style={fieldStyle} />
        </div>
        <button disabled={busy || !selectedMerchantId} onClick={createBranch} style={{ ...buttonStyle, marginTop: 12 }}>إنشاء الفرع</button>
        <div style={{ marginTop: 14 }}>
          {branches.map((b) => {
            const merchant = b.merchants as { name?: string } | undefined;
            return <div key={String(b.id)} style={{ borderTop: "1px solid #e5e7eb", padding: "10px 0", display: "flex", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
              <span>{String(b.name)} — {merchant?.name || "متجر"} — {String(b.address)} — {b.is_active ? "نشط" : "غير منشور"}</span>
              <button disabled={busy} onClick={() => setBranchActive(String(b.id), !Boolean(b.is_active))} style={secondaryButton}>
                {b.is_active ? "إيقاف النشر" : "تفعيل الفرع"}
              </button>
            </div>;
          })}
        </div>
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

const fieldStyle: CSSProperties = { width: "100%", boxSizing: "border-box", padding: 13, border: "1px solid #D8D0BC", borderRadius: 10, fontSize: 16, background: "#FFFEFA", color: "#17251D" };
const buttonStyle: CSSProperties = { padding: "13px 16px", border: "1px solid #D8BC79", borderRadius: 10, background: "#145A3A", color: "#FFFFFF", fontWeight: 800, cursor: "pointer" };
const secondaryButton: CSSProperties = { padding: "9px 12px", border: "1px solid #B99A55", borderRadius: 9, background: "#FBF8EF", color: "#173B29", cursor: "pointer", fontWeight: 700 };
const tileStyle: CSSProperties = { background: "#FFFEFA", border: "1px solid #DED3B7", borderTop: "3px solid #B99A55", borderRadius: 14, padding: 16, boxShadow: "0 6px 20px rgba(22,42,30,.05)" };
const panelStyle: CSSProperties = { background: "#FFFEFA", border: "1px solid #DED3B7", borderRadius: 16, padding: 20, marginTop: 18, boxShadow: "0 8px 24px rgba(22,42,30,.04)" };
const loginShellStyle: CSSProperties = { minHeight: "100vh", display: "grid", placeItems: "center", padding: 24, boxSizing: "border-box", background: "radial-gradient(circle at 15% 15%, #1D6544 0, #0C261A 36%, #090F0C 100%)" };
const loginCardStyle: CSSProperties = { width: "100%", maxWidth: 440, boxSizing: "border-box", padding: 30, borderRadius: 22, border: "1px solid rgba(216,188,121,.5)", background: "linear-gradient(160deg, rgba(19,48,33,.98), rgba(10,20,14,.98))", boxShadow: "0 24px 80px rgba(0,0,0,.35)" };
const brandMarkStyle: CSSProperties = { display: "inline-flex", alignItems: "center", gap: 2, fontSize: 42, fontWeight: 950, letterSpacing: -3, marginBottom: 16, borderBottom: "3px solid #B99A55", paddingBottom: 4 };
const brandMarkSmallStyle: CSSProperties = { display: "inline-flex", alignItems: "center", gap: 2, fontSize: 28, fontWeight: 950, letterSpacing: -2, borderBottom: "2px solid #D8BC79", paddingBottom: 2 };
const dashboardHeaderStyle: CSSProperties = { display: "flex", justifyContent: "space-between", alignItems: "center", gap: 16, flexWrap: "wrap", padding: 24, borderRadius: 20, background: "linear-gradient(110deg, #0D2B1D, #174D34 70%, #101A14)", border: "1px solid #B99A55", boxShadow: "0 12px 30px rgba(12,38,26,.14)" };
const authMessageStyle: CSSProperties = { color: "#FFE4DF", background: "rgba(155,36,42,.28)", border: "1px solid rgba(230,125,116,.5)", padding: 12, borderRadius: 10, lineHeight: 1.7 };
