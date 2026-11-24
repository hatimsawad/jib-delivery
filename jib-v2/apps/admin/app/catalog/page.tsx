"use client";

import { useEffect, useState, type FormEvent } from "react";
import { createClient, type User } from "@supabase/supabase-js";

const supabase = createClient("https://ldgbyshgcifheditplnn.supabase.co", "sb_publishable_wvNMRZTBFX4viI2ypcdWjQ_YBqgi_TV");
type Brand = { id: string; name: string; slug: string; category: string | null; logo_url: string | null; website_url: string | null; is_approved: boolean; is_active: boolean };
type Product = { id: string; brand_id: string | null; name: string; category: string | null; description: string | null; image_url: string | null; reference_price_mad: number | null; official_source_url: string | null; is_active: boolean };
const inputStyle: React.CSSProperties = { width: "100%", boxSizing: "border-box", padding: 11, border: "1px solid #D8E2DC", borderRadius: 9, fontSize: 15, background: "#fff", color: "#17231b" };
const buttonStyle: React.CSSProperties = { border: 0, borderRadius: 9, padding: "11px 16px", background: "#E31E24", color: "#fff", fontWeight: 800, cursor: "pointer" };
const panelStyle: React.CSSProperties = { background: "#fff", border: "1px solid #D8E2DC", borderRadius: 14, padding: 18, marginTop: 16 };

export default function CatalogAdminPage() {
  const [user, setUser] = useState<User | null>(null);
  const [authorized, setAuthorized] = useState(false);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [tab, setTab] = useState<"products" | "brands">("products");
  const [brands, setBrands] = useState<Brand[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [search, setSearch] = useState("");
  const [brandId, setBrandId] = useState("");
  const [brandName, setBrandName] = useState("");
  const [brandSlug, setBrandSlug] = useState("");
  const [brandCategory, setBrandCategory] = useState("");
  const [brandLogo, setBrandLogo] = useState("");
  const [brandWebsite, setBrandWebsite] = useState("");
  const [brandApproved, setBrandApproved] = useState(true);
  const [brandActive, setBrandActive] = useState(true);
  const [productId, setProductId] = useState("");
  const [productName, setProductName] = useState("");
  const [productBrand, setProductBrand] = useState("");
  const [productCategory, setProductCategory] = useState("");
  const [productDescription, setProductDescription] = useState("");
  const [productImage, setProductImage] = useState("");
  const [referencePrice, setReferencePrice] = useState("");
  const [sourceUrl, setSourceUrl] = useState("");
  const [productActive, setProductActive] = useState(true);

  async function loadCatalog() {
    setLoading(true); setError("");
    try {
      const [brandRows, productRows] = await Promise.all([
        supabase.from("brands").select("id,name,slug,category,logo_url,website_url,is_approved,is_active").order("name").limit(500),
        supabase.from("products").select("id,brand_id,name,category,description,image_url,reference_price_mad,official_source_url,is_active").order("name").limit(1000),
      ]);
      if (brandRows.error) throw brandRows.error;
      if (productRows.error) throw productRows.error;
      setBrands((brandRows.data ?? []) as Brand[]);
      setProducts((productRows.data ?? []) as Product[]);
    } catch { setError("تعذر تحميل الكتالوج. تحقق من صلاحية المدير واتصال قاعدة JIB V2."); }
    finally { setLoading(false); }
  }

  useEffect(() => {
    let active = true;
    supabase.auth.getSession().then(async ({ data }) => {
      if (!active) return;
      const current = data.session?.user ?? null;
      setUser(current);
      if (!current) { setLoading(false); return; }
      const { data: profile, error: profileError } = await supabase.from("profiles").select("role").eq("id", current.id).maybeSingle();
      if (!active) return;
      const isAdmin = !profileError && profile?.role === "admin";
      setAuthorized(isAdmin);
      if (isAdmin) await loadCatalog(); else setLoading(false);
    });
    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!active) return;
      setUser(session?.user ?? null);
      if (!session?.user) { setAuthorized(false); setBrands([]); setProducts([]); }
    });
    return () => { active = false; listener.subscription.unsubscribe(); };
  }, []);

  function resetBrand() { setBrandId(""); setBrandName(""); setBrandSlug(""); setBrandCategory(""); setBrandLogo(""); setBrandWebsite(""); setBrandApproved(true); setBrandActive(true); }
  function editBrand(b: Brand) {
    setTab("brands"); setBrandId(b.id); setBrandName(b.name); setBrandSlug(b.slug);
    setBrandCategory(b.category ?? ""); setBrandLogo(b.logo_url ?? ""); setBrandWebsite(b.website_url ?? "");
    setBrandApproved(b.is_approved); setBrandActive(b.is_active); setNotice("");
  }
  function resetProduct() {
    setProductId(""); setProductName(""); setProductBrand(""); setProductCategory(""); setProductDescription("");
    setProductImage(""); setReferencePrice(""); setSourceUrl(""); setProductActive(true);
  }
  function editProduct(p: Product) {
    setTab("products"); setProductId(p.id); setProductName(p.name); setProductBrand(p.brand_id ?? "");
    setProductCategory(p.category ?? ""); setProductDescription(p.description ?? ""); setProductImage(p.image_url ?? "");
    setReferencePrice(p.reference_price_mad == null ? "" : String(p.reference_price_mad));
    setSourceUrl(p.official_source_url ?? ""); setProductActive(p.is_active); setNotice("");
  }

  async function toggleBrandVisibility(brand: Brand) {
    setBusy(true); setError(""); setNotice("");
    const nextActive = !brand.is_active;
    const { error: updateError } = await supabase.from("brands")
      .update({ is_active: nextActive }).eq("id", brand.id);
    if (updateError) setError("تعذر تغيير ظهور المتجر. تحقق من صلاحيات المدير.");
    else {
      setBrands(current => current.map(item => item.id === brand.id ? { ...item, is_active: nextActive } : item));
      setNotice(nextActive ? `تم تشغيل ظهور ${brand.name} في تطبيق الزبون.` : `تم إيقاف ظهور ${brand.name} في تطبيق الزبون.`);
    }
    setBusy(false);
  }

  async function saveBrand(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!brandName.trim() || !brandSlug.trim()) { setError("اسم العلامة والمعرّف المختصر مطلوبان."); return; }
    setBusy(true); setError(""); setNotice("");
    const values = { name: brandName.trim(), slug: brandSlug.trim().toLowerCase(), category: brandCategory.trim() || null,
      logo_url: brandLogo.trim() || null, website_url: brandWebsite.trim() || null, is_approved: brandApproved, is_active: brandActive };
    const result = brandId ? await supabase.from("brands").update(values).eq("id", brandId) : await supabase.from("brands").insert(values);
    if (result.error) setError("تعذر حفظ العلامة. تحقق من أن المعرّف المختصر غير مستخدم.");
    else { setNotice("تم حفظ العلامة في كتالوج JIB V2."); resetBrand(); await loadCatalog(); }
    setBusy(false);
  }

  async function saveProduct(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!productName.trim()) { setError("اسم المنتج مطلوب."); return; }
    const parsedPrice = referencePrice.trim() === "" ? null : Number(referencePrice);
    if (parsedPrice !== null && (!Number.isFinite(parsedPrice) || parsedPrice < 0)) { setError("السعر المرجعي يجب أن يكون رقماً صحيحاً غير سالب."); return; }
    setBusy(true); setError(""); setNotice("");
    const values = { name: productName.trim(), brand_id: productBrand || null, category: productCategory.trim() || null,
      description: productDescription.trim() || null, image_url: productImage.trim() || null, reference_price_mad: parsedPrice,
      official_source_url: sourceUrl.trim() || null, is_active: productActive };
    const result = productId ? await supabase.from("products").update(values).eq("id", productId) : await supabase.from("products").insert(values);
    if (result.error) setError("تعذر حفظ المنتج. تحقق من العلامة المختارة والبيانات المدخلة.");
    else { setNotice("تم حفظ المنتج. السعر المدخل هنا مرجعي فقط ولا ينشئ عرض بيع لأي فرع."); resetProduct(); await loadCatalog(); }
    setBusy(false);
  }

  if (!user) return <main style={{ maxWidth: 650, margin: "40px auto", padding: 20, direction: "rtl" }}>
    <section style={panelStyle}><h1>إدارة كتالوج JIB</h1><p>سجّل الدخول أولاً من لوحة الإدارة.</p><a href="/">العودة إلى تسجيل الدخول</a></section>
  </main>;
  if (!authorized && !loading) return <main style={{ maxWidth: 650, margin: "40px auto", padding: 20, direction: "rtl" }}>
    <section style={panelStyle}><h1>غير مصرح</h1><p>هذه الصفحة مخصصة لحساب مدير JIB V2 فقط.</p><a href="/">العودة إلى لوحة الإدارة</a></section>
  </main>;

  const filteredProducts = products.filter(p => p.name.toLowerCase().includes(search.toLowerCase()));
  const filteredBrands = brands.filter(b => b.name.toLowerCase().includes(search.toLowerCase()));

  return <main style={{ maxWidth: 1180, margin: "0 auto", padding: 22, direction: "rtl", background: "#F7F8F7", minHeight: "100vh", color: "#17231b" }}>
    <header style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 12, background: "linear-gradient(110deg,#101612,#00843D)", padding: 22, borderRadius: 16, color: "#fff" }}>
      <div><div style={{ fontSize: 26, fontWeight: 950 }}>★ JIB</div><h1 style={{ margin: "8px 0 0" }}>إدارة المتاجر والمنتجات</h1></div>
      <a href="/" style={{ color: "#fff", fontWeight: 800 }}>العودة إلى لوحة القيادة</a>
    </header>
    {error && <p role="alert" style={{ background: "#FEE2E2", color: "#991B1B", padding: 12, borderRadius: 9 }}>{error}</p>}
    {notice && <p role="status" style={{ background: "#E8F5E9", color: "#14532D", padding: 12, borderRadius: 9 }}>{notice}</p>}
    <section style={panelStyle}>
      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
        <button type="button" onClick={() => setTab("products")} style={{ ...buttonStyle, background: tab === "products" ? "#E31E24" : "#00843D" }}>المنتجات ({products.length})</button>
        <button type="button" onClick={() => setTab("brands")} style={{ ...buttonStyle, background: tab === "brands" ? "#E31E24" : "#00843D" }}>العلامات ({brands.length})</button>
        <button type="button" onClick={loadCatalog} style={{ ...buttonStyle, background: "#fff", color: "#00843D", border: "1px solid #00843D" }}>تحديث البيانات</button>
      </div>
      <input value={search} onChange={e => setSearch(e.target.value)} placeholder="ابحث بالاسم..." style={{ ...inputStyle, marginTop: 14 }} />
      {loading && <p>جارٍ تحميل الكتالوج...</p>}
      {!loading && tab === "products" && <div style={{ display: "grid", gridTemplateColumns: "minmax(280px,1fr) minmax(300px,1fr)", gap: 18, marginTop: 16 }}>
        <form onSubmit={saveProduct} style={{ display: "grid", gap: 9, alignContent: "start" }}>
          <h2>{productId ? "تعديل منتج" : "إضافة منتج"}</h2>
          <input required value={productName} onChange={e => setProductName(e.target.value)} placeholder="اسم المنتج" style={inputStyle} />
          <select value={productBrand} onChange={e => setProductBrand(e.target.value)} style={inputStyle}><option value="">بدون علامة</option>{brands.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}</select>
          <input value={productCategory} onChange={e => setProductCategory(e.target.value)} placeholder="القسم / التصنيف" style={inputStyle} />
          <textarea value={productDescription} onChange={e => setProductDescription(e.target.value)} placeholder="وصف المنتج" rows={3} style={inputStyle} />
          <input value={productImage} onChange={e => setProductImage(e.target.value)} placeholder="رابط صورة المنتج (HTTPS)" style={inputStyle} />
          <input value={referencePrice} onChange={e => setReferencePrice(e.target.value)} placeholder="السعر المرجعي بالدرهم (اختياري)" inputMode="decimal" style={inputStyle} />
          <input value={sourceUrl} onChange={e => setSourceUrl(e.target.value)} placeholder="رابط المصدر الرسمي" style={inputStyle} />
          <label><input type="checkbox" checked={productActive} onChange={e => setProductActive(e.target.checked)} /> المنتج ظاهر في الكتالوج</label>
          <p style={{ fontSize: 12, color: "#64748B", margin: 0 }}>السعر المرجعي لا يُعد سعر فرع ولا يجعل المنتج قابلاً للشراء. السعر الفعلي والتوفر يؤكدهما التاجر داخل تطبيقه.</p>
          <div style={{ display: "flex", gap: 8 }}><button disabled={busy} style={buttonStyle}>{busy ? "جارٍ الحفظ..." : "حفظ المنتج"}</button><button type="button" onClick={resetProduct} style={{ ...buttonStyle, background: "#64748B" }}>مسح</button></div>
        </form>
        <div style={{ maxHeight: 650, overflow: "auto" }}>
          {filteredProducts.map(p => <article key={p.id} style={{ borderBottom: "1px solid #E5E7EB", padding: "10px 0", display: "flex", gap: 10, alignItems: "center" }}>
            {p.image_url && <img src={p.image_url} alt="" width={54} height={54} style={{ objectFit: "contain", background: "#F7F8F7", borderRadius: 8 }} />}
            <div style={{ flex: 1 }}><strong>{p.name}</strong><div style={{ fontSize: 12, color: "#64748B" }}>{p.is_active ? "نشط" : "مخفي"} · {p.reference_price_mad == null ? "بدون سعر مرجعي" : "مرجعي: " + p.reference_price_mad + " د.م."}</div></div>
            <button type="button" onClick={() => editProduct(p)} style={{ ...buttonStyle, padding: "7px 10px" }}>تعديل</button>
          </article>)}
        </div>
      </div>}
      {!loading && tab === "brands" && <div style={{ display: "grid", gridTemplateColumns: "minmax(280px,1fr) minmax(300px,1fr)", gap: 18, marginTop: 16 }}>
        <form onSubmit={saveBrand} style={{ display: "grid", gap: 9, alignContent: "start" }}>
          <h2>{brandId ? "تعديل متجر" : "إضافة متجر"}</h2>
          <input required value={brandName} onChange={e => setBrandName(e.target.value)} placeholder="اسم العلامة" style={inputStyle} />
          <input required value={brandSlug} onChange={e => setBrandSlug(e.target.value)} placeholder="المعرّف المختصر (slug)" style={inputStyle} />
          <input value={brandCategory} onChange={e => setBrandCategory(e.target.value)} placeholder="القسم" style={inputStyle} />
          <input value={brandLogo} onChange={e => setBrandLogo(e.target.value)} placeholder="رابط شعار العلامة (HTTPS)" style={inputStyle} />
          <input value={brandWebsite} onChange={e => setBrandWebsite(e.target.value)} placeholder="الموقع الرسمي" style={inputStyle} />
          <label><input type="checkbox" checked={brandApproved} onChange={e => setBrandApproved(e.target.checked)} /> اعتماد العلامة</label>
          <label><input type="checkbox" checked={brandActive} onChange={e => setBrandActive(e.target.checked)} /> إظهار المتجر</label>
          <div style={{ display: "flex", gap: 8 }}><button disabled={busy} style={buttonStyle}>{busy ? "جارٍ الحفظ..." : "حفظ العلامة"}</button><button type="button" onClick={resetBrand} style={{ ...buttonStyle, background: "#64748B" }}>مسح</button></div>
        </form>
        <div style={{ maxHeight: 650, overflow: "auto" }}>
          {filteredBrands.map(b => <article key={b.id} style={{ borderBottom: "1px solid #E5E7EB", padding: "10px 0", display: "flex", gap: 10, alignItems: "center" }}>
            {b.logo_url && <img src={b.logo_url} alt="" width={44} height={44} style={{ objectFit: "contain", background: "#F7F8F7", borderRadius: 8 }} />}
            <div style={{ flex: 1 }}><strong>{b.name}</strong><div style={{ fontSize: 12, color: "#64748B" }}>{b.is_approved ? "معتمدة" : "بانتظار الاعتماد"} · {b.is_active ? "ظاهرة" : "مخفية"}</div></div>
            <button type="button" disabled={busy} onClick={() => toggleBrandVisibility(b)} style={{ ...buttonStyle, padding: "7px 10px", background: b.is_active ? "#64748B" : "#00843D" }}>{b.is_active ? "إيقاف المتجر" : "تشغيل المتجر"}</button>
            <button type="button" onClick={() => editBrand(b)} style={{ ...buttonStyle, padding: "7px 10px" }}>تعديل</button>
          </article>)}
        </div>
      </div>}
    </section>
    <footer style={{ color: "#64748B", fontSize: 12, marginTop: 14 }}>JIB V2 · إدارة الكتالوج فقط · لا تُنشأ أسعار أو عروض فروع أو رسوم أو وسائل دفع تلقائياً.</footer>
  </main>;
}
