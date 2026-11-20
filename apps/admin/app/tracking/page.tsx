import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";

export const dynamic = "force-dynamic";

type TrackingRow = {
  courier_id: string;
  consented_at: string;
  tracking_enabled: boolean;
  last_location_at: string | null;
  stopped_at: string | null;
  updated_at: string;
};
type LocationRow = {
  courier_id: string;
  latitude: number;
  longitude: number;
  accuracy_m: number;
  recorded_at: string;
};
type ReadQuery<T> = {
  order(column: string, options?: { ascending?: boolean }): {
    limit(count: number): Promise<{ data: T[] | null; error: { message: string } | null }>;
  };
};
type TrackingReadClient = {
  from(table: string): {
    select(columns: string): ReadQuery<TrackingRow> | ReadQuery<LocationRow>;
  };
};

function formatDate(value: string | null) {
  if (!value) return "لم يصل أي تحديث بعد";
  return new Date(value).toLocaleString("ar-MA", { timeZone: "Africa/Casablanca", dateStyle: "medium", timeStyle: "short" });
}
function ageLabel(value: string | null) {
  if (!value) return "لم يبدأ إرسال الموقع";
  const seconds = Math.max(0, Math.floor((Date.now() - new Date(value).getTime()) / 1000));
  if (seconds > 60) return `منقطع منذ ${Math.floor(seconds / 60)} دقيقة و${seconds % 60} ثانية`;
  return `آخر تحديث منذ ${seconds} ثانية`;
}

export default async function CourierTrackingPage() {
  const { supabase } = await requireAdmin();
  const db = supabase as unknown as TrackingReadClient;
  const [trackingResult, locationResult] = await Promise.all([
    db.from("courier_location_tracking").select("courier_id,consented_at,tracking_enabled,last_location_at,stopped_at,updated_at").order("updated_at", { ascending: false }).limit(100),
    db.from("courier_location_events").select("courier_id,latitude,longitude,accuracy_m,recorded_at").order("recorded_at", { ascending: false }).limit(500),
  ]);
  const trackingRows = (trackingResult.data ?? []) as TrackingRow[];
  const locationRows = (locationResult.data ?? []) as LocationRow[];
  const latest = new Map<string, LocationRow>();
  for (const row of locationRows) if (!latest.has(row.courier_id)) latest.set(row.courier_id, row);
  const readError = Boolean(trackingResult.error || locationResult.error);

  return (
    <main className="shell">
      <AdminHeader />
      <section className="page-heading">
        <p className="eyebrow">JIB OPERATIONS · LIVE COURIER LOCATION</p>
        <h1>تتبع المندوبين</h1>
        <p>تظهر هنا المواقع التي وافق المندوب صراحة على مشاركتها. يصدر تنبيه عند انقطاع التحديث أكثر من 60 ثانية، وتحذف نقاط المسار آلياً بعد 90 يوماً.</p>
      </section>
      {readError && <p className="error-state">تعذر قراءة سجل التتبع. تحقق من صلاحيات قاعدة البيانات.</p>}
      <section className="list-panel">
        <div className="section-heading"><h2>جلسات مشاركة الموقع</h2><span className="count-chip">{trackingRows.length} جلسات</span></div>
        {trackingRows.length === 0 ? (
          <div className="empty-state"><strong>لا توجد جلسات مشاركة حالياً</strong><span>لن يظهر موقع أي مندوب قبل موافقته الصريحة وتفعيل GPS.</span></div>
        ) : (
          <div className="manager-event-list">
            {trackingRows.map((row) => {
              const point = latest.get(row.courier_id);
              const stale = row.tracking_enabled && (!row.last_location_at || Date.now() - new Date(row.last_location_at).getTime() > 60_000);
              return (
                <article className={`manager-event manager-event-${stale ? "warning" : row.tracking_enabled ? "info" : "resolved"}`} key={row.courier_id}>
                  <div className="manager-event-heading">
                    <strong>مندوب · {row.courier_id.slice(0, 8)}</strong>
                    <span>{!row.tracking_enabled ? "متوقف بموافقة المندوب" : stale ? "انقطاع أكثر من 60 ثانية" : "يرسل الموقع"}</span>
                  </div>
                  <p>{ageLabel(row.last_location_at)}</p>
                  {point && (
                    <p dir="ltr">
                      {point.latitude.toFixed(6)}, {point.longitude.toFixed(6)} · دقة {Math.round(point.accuracy_m)} م
                    </p>
                  )}
                  <small>آخر نقطة: {formatDate(row.last_location_at)} · الموافقة: {formatDate(row.consented_at)}</small>
                </article>
              );
            })}
          </div>
        )}
      </section>
    </main>
  );
}
