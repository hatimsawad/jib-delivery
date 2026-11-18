import AdminHeader from "../../../admin-header";
import { requireAdmin } from "../../../admin-data";

export const dynamic = "force-dynamic";

const channelLabels: Record<string, string> = {
  email: "البريد الإلكتروني",
  sms: "الرسائل النصية SMS",
  whatsapp: "واتساب",
  voice: "المكالمات الصوتية",
};

const languageLabels: Record<string, string> = { ar: "العربية", fr: "الفرنسية" };

export default async function NotificationSettingsPage() {
  const { supabase } = await requireAdmin();
  const { data, error } = await supabase
    .from("jib_ai_manager_settings")
    .select("notification_email,notification_phone,notification_channels,notification_call_mode,notification_voice_languages,updated_at")
    .eq("id", 1)
    .maybeSingle();

  return (
    <main className="shell">
      <AdminHeader />
      <section className="page-heading">
        <p className="eyebrow">JIB AI MANAGER · الإعدادات</p>
        <h1>التنبيهات والاتصالات</h1>
        <p>إعدادات التنبيه الخاصة بمركز الإدارة، محفوظة في قاعدة بيانات JIB ومحمية بصلاحيات المدير.</p>
      </section>
      {error ? (
        <p className="error-state">تعذر قراءة إعدادات التنبيه. تحقق من وجود ترحيل قاعدة البيانات وصلاحية المدير.</p>
      ) : !data ? (
        <div className="list-panel"><div className="empty-state"><strong>لم تُسجل إعدادات بعد</strong><span>أضف إعدادات الاتصال من خلال إجراء إداري آمن بعد تهيئة مزودي الخدمة.</span></div></div>
      ) : (
        <>
          <section className="manager-settings-grid">
            <article className="metric"><span>البريد المخصص للتنبيهات</span><b className="settings-value">{data.notification_email || "غير محدد"}</b><small>وجهة التنبيه المحفوظة</small></article>
            <article className="metric"><span>الهاتف المخصص للتنبيهات</span><b className="settings-value" dir="ltr">{data.notification_phone || "غير محدد"}</b><small>رقم الاتصال المسجل</small></article>
            <article className="metric"><span>سياسة المكالمات</span><b className="settings-value">{data.notification_call_mode === "all_events" ? "كل التحديثات والأحداث" : data.notification_call_mode}</b><small>حسب الإعداد المحفوظ</small></article>
            <article className="metric"><span>لغات المكالمات</span><b className="settings-value">{(data.notification_voice_languages ?? []).map((language) => languageLabels[language] ?? language).join(" · ") || "غير محددة"}</b><small>لغات الصوت المعتمدة</small></article>
          </section>
          <section className="list-panel">
            <div className="section-heading"><h2>قنوات التنبيه المطلوبة</h2><span className="count-chip">{data.notification_channels.length} قنوات</span></div>
            <div className="manager-channel-list">
              {data.notification_channels.map((channel) => <span className="manager-channel" key={channel}>{channelLabels[channel] ?? channel}</span>)}
            </div>
            <p className="manager-provider-note">تنبيه تشغيلي: هذه القنوات محفوظة كتفضيلات. لا نعرضها على أنها تعمل فعلياً حتى يتم ربط مزود كل قناة وإجراء اختبار إرسال واستلام ناجح. لا تزال حالة اتصال المزود غير مؤكدة.</p>
            <small className="settings-updated">آخر تحديث للإعدادات: {new Date(data.updated_at).toLocaleString("ar-MA", { timeZone: "Africa/Casablanca" })}</small>
          </section>
        </>
      )}
    </main>
  );
}
