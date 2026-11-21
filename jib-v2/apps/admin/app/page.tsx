const tiles = [
  ["الطلبات النشطة", "—", "تتطلب ربط بيئة V2"],
  ["التجار والفروع", "—", "إدارة الحسابات المعتمدة"],
  ["المندوبون", "—", "حالة التوفر والمهام"],
  ["الكتالوج", "—", "العلامات والمنتجات والأسعار"],
];

export default function AdminHome() {
  return (
    <main style={{ maxWidth: 1120, margin: "0 auto", padding: 32 }}>
      <header style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 16, flexWrap: "wrap" }}>
        <div>
          <p style={{ color: "#64748b", marginBottom: 8 }}>JIB V2 · مساحة تشغيل داخلية</p>
          <h1 style={{ margin: 0, fontSize: 30 }}>لوحة الإدارة</h1>
        </div>
        <span style={{ background: "#fff7ed", color: "#9a3412", padding: "9px 13px", borderRadius: 10 }}>وضع التطوير — غير متصلة ببيانات حقيقية</span>
      </header>
      <section style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit,minmax(210px,1fr))", gap: 16, marginTop: 28 }}>
        {tiles.map(([label, value, detail]) => (
          <article key={label} style={{ background: "white", border: "1px solid #e5e7eb", borderRadius: 16, padding: 20 }}>
            <p style={{ color: "#64748b", marginTop: 0 }}>{label}</p>
            <strong style={{ fontSize: 30 }}>{value}</strong>
            <p style={{ color: "#64748b", marginBottom: 0 }}>{detail}</p>
          </article>
        ))}
      </section>
      <section style={{ background: "white", border: "1px solid #e5e7eb", borderRadius: 16, padding: 22, marginTop: 20 }}>
        <h2 style={{ marginTop: 0 }}>حالة النظام</h2>
        <p>هذه واجهة تأسيسية فقط. لن تظهر بيانات العملاء أو الطلبات قبل إعداد خادم V2 مستقل وتفعيل تسجيل دخول الموظفين والصلاحيات.</p>
      </section>
    </main>
  );
}
