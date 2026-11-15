const metrics = [
  { label: "الطلبات اليوم", value: "—", note: "ستظهر البيانات بعد ربط قاعدة البيانات" },
  { label: "المتاجر النشطة", value: "—", note: "بانتظار ربط Supabase" },
  { label: "السائقون المتصلون", value: "—", note: "بانتظار ربط Supabase" },
  { label: "حجم المبيعات", value: "—", note: "بالدرهم المغربي" },
];
export default function Home() {
  return <main className="shell">
    <header className="topbar"><div className="brand"><span className="mark">J</span><div><strong>جيب JIB</strong><small>منصة التوصيل · الرباط</small></div></div><span className="status">نسخة تأسيسية</span></header>
    <section className="hero"><p className="eyebrow">لوحة التحكم المركزية</p><h1>كلشي قريب ليك.</h1><p>إدارة الطلبات والمتاجر والسائقين من مكان واحد.</p></section>
    <section className="metrics">{metrics.map((m) => <article className="metric" key={m.label}><span>{m.label}</span><b>{m.value}</b><small>{m.note}</small></article>)}</section>
    <section className="panel"><div><h2>مساحة العمل جاهزة للربط</h2><p>تم إنشاء الهيكل الأولي للوحة الإدارة. الأرقام والعمليات الحقيقية لن تظهر حتى نربط قاعدة البيانات ونفعّل تسجيل الدخول والصلاحيات.</p></div><ul><li>إدارة الطلبات وحالاتها</li><li>مراجعة المتاجر والمنتجات</li><li>متابعة السائقين ومناطق الخدمة</li><li>مؤشرات الأداء والتقارير</li></ul></section>
    <footer>JIB © 2026 · الرباط، المغرب</footer>
  </main>;
}
