import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";

export const dynamic = "force-dynamic";

type HealthCheck = {
  checked_at: string;
  status: "healthy" | "degraded" | "down";
  website_status: number | null;
  duration_ms: number;
  metrics: {
    orders?: number | null;
    active_stores?: number | null;
    products?: number | null;
    active_couriers?: number | null;
    provider_delivery_configured?: boolean;
    product_image_bucket_available?: boolean;
  };
  issues: string[];
};

type ManagerEvent = {
  id: string;
  event_type: string;
  severity: "info" | "warning" | "critical";
  title: string;
  message: string;
  status: "open" | "acknowledged" | "resolved";
  occurrence_count: number;
  last_seen_at: string;
};

const severityLabels = { info: "معلومة", warning: "تحذير", critical: "حرج" } as const;
const eventTypeLabels: Record<string, string> = { health_check: "مراقبة النظام", order_status: "تحديث طلب", product_change: "تغيير منتج", store_change: "تغيير متجر", profile_role_change: "تغيير صلاحية", courier_approval: "اعتماد مندوب", health_check_resolution: "حل مشكلة تشغيلية" };

const statusLabels = {
  healthy: "سليم",
  degraded: "يحتاج مراجعة",
  down: "متوقف أو غير متاح",
} as const;

function formatDate(value: string) {
  return new Date(value).toLocaleString("ar-MA", {
    timeZone: "Africa/Casablanca",
    dateStyle: "medium",
    timeStyle: "short",
  });
}

export default async function MonitoringPage() {
  const { supabase } = await requireAdmin();
  const [healthResult, eventsResult] = await Promise.all([
    supabase
      .from("jib_ai_manager_health_checks")
      .select("checked_at,status,website_status,duration_ms,metrics,issues")
      .order("checked_at", { ascending: false })
      .limit(1),
    supabase
      .from("jib_ai_manager_events")
      .select("id,event_type,severity,title,message,status,occurrence_count,last_seen_at")
      .order("last_seen_at", { ascending: false })
      .limit(10),
  ]);

  const healthRows = healthResult.data as unknown as HealthCheck[] | null;
  const eventRows = eventsResult.data as unknown as ManagerEvent[] | null;
  const latest = healthRows?.[0] ?? null;
  const events = eventRows ?? [];
  const readError = Boolean(healthResult.error || eventsResult.error);

  return (
    <main className="shell">
      <AdminHeader />
      <section className="page-heading">
        <p className="eyebrow">JIB AI MANAGER · المراقبة المستمرة</p>
        <h1>صحة المنصة والحوادث</h1>
        <p>فحص آلي كل خمس دقائق للموقع واتصال قاعدة البيانات، مع سجل للحوادث وتكرارها.</p>
      </section>

      {readError && <p className="error-state">تعذر تحميل بعض بيانات المراقبة. تحقق من اتصال قاعدة البيانات وصلاحيات المدير.</p>}

      {latest ? (
        <>
          <section className="manager-settings-grid">
            <article className="metric">
              <span>الحالة العامة</span>
              <b className="settings-value">{statusLabels[latest.status]}</b>
              <small>آخر فحص: {formatDate(latest.checked_at)}</small>
            </article>
            <article className="metric">
              <span>الموقع الإلكتروني</span>
              <b className="settings-value">{latest.website_status ?? "غير متاح"}</b>
              <small>HTTP status · jib-admin-two.vercel.app</small>
            </article>
            <article className="metric">
              <span>زمن الفحص</span>
              <b className="settings-value">{latest.duration_ms} ms</b>
              <small>من بداية الفحص حتى حفظ النتيجة</small>
            </article>
            <article className="metric">
              <span>المتاجر والمندوبون</span>
              <b className="settings-value">{latest.metrics.active_stores ?? "—"} / {latest.metrics.active_couriers ?? "—"}</b>
              <small>متاجر نشطة / مندوبون نشطون</small>
            </article>
            <article className="metric">
              <span>تخزين صور المنتجات</span>
              <b className="settings-value">{latest.metrics.product_image_bucket_available ? "متصل" : "غير متاح"}</b>
              <small>Supabase Storage · product-images</small>
            </article>
            <article className="metric">
              <span>تنبيهات بانتظار ربط المزود</span>
              <b className="settings-value">{notificationQueueCount}</b>
              <small>لن تُرسل قبل تفعيل الخدمات وموافقتك</small>
            </article>
          </section>
          <section className="list-panel">
            <div className="section-heading"><h2>مؤشرات قاعدة البيانات</h2><span className="count-chip">آخر فحص</span></div>
            <div className="manager-settings-grid">
              <article className="metric"><span>الطلبات</span><b>{latest.metrics.orders ?? "—"}</b></article>
              <article className="metric"><span>المنتجات</span><b>{latest.metrics.products ?? "—"}</b></article>
              <article className="metric"><span>المتاجر النشطة</span><b>{latest.metrics.active_stores ?? "—"}</b></article>
              <article className="metric"><span>المندوبون النشطون</span><b>{latest.metrics.active_couriers ?? "—"}</b></article>
            </div>
            <p className="manager-provider-note">
              فحص المراقبة يعمل، لكن إرسال البريد وSMS وWhatsApp والمكالمات لم يُفعّل بعد لعدم ربط حسابات مزودي الإرسال.
            </p>
          </section>
        </>
      ) : (
        <section className="list-panel"><div className="empty-state"><strong>لا توجد نتائج فحص بعد</strong><span>سيظهر أول فحص بعد تشغيل المهمة المجدولة.</span></div></section>
      )}

      <section className="list-panel">
        <div className="section-heading"><h2>الحوادث والتنبيهات التشغيلية</h2><span className="count-chip">{events.length} سجلات</span></div>
        {events.length === 0 ? (
          <div className="empty-state"><strong>لا توجد حوادث مسجلة</strong><span>سيظهر هنا أي فشل في الموقع أو قراءة قاعدة البيانات.</span></div>
        ) : (
          <div className="manager-event-list">
            {events.map((event) => (
              <article className={`manager-event manager-event-${event.severity}`} key={event.id}>
                <div className="manager-event-heading"><strong>{event.title}</strong><span>{severityLabels[event.severity]}</span></div>
                <p>{event.message}</p>
                <small>{eventTypeLabels[event.event_type] ?? event.event_type} · {event.event_type === "health_check" ? (event.status === "open" ? "مفتوح" : "تم الحل") : "سجل نشاط"} · تكرر {event.occurrence_count} مرة · {formatDate(event.last_seen_at)}</small>
              </article>
            ))}
          </div>
        )}
      </section>
    </main>
  );
}
