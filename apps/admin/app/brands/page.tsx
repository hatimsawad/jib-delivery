import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";
import { createCommercialBrand, updateCommercialBrandStatus } from "./actions";

type BrandRow = {
  id: string; name: string; slug: string; category: string;
  website_url: string | null; country_code: string | null;
  status: string; source_name: string | null; created_at: string;
};

const categoryLabels: Record<string, string> = {
  "prepared-food":"مطاعم ووجبات", bakery:"مخابز", beverages:"مشروبات",
  grocery:"بقالة وسوبرماركت", "fresh-produce":"خضر وفواكه",
  "meat-seafood":"لحوم وأسماك", household:"منتجات منزلية",
  "personal-care":"عناية شخصية", electronics:"إلكترونيات", fashion:"أزياء",
  beauty:"تجميل", "flowers-gifts":"زهور وهدايا", "toys-games":"ألعاب",
  "books-stationery":"كتب وقرطاسية", "pet-supplies":"مستلزمات الحيوانات",
  "sports-outdoors":"رياضة", automotive:"سيارات", pharmacy:"صيدليات",
  "general-merchandise":"سلع متنوعة",
};
const statusLabels: Record<string,string> = {
  draft:"مسودة", pending_verification:"بانتظار المراجعة",
  approved:"معتمدة في الكتالوج", rejected:"مرفوضة", suspended:"موقوفة",
};
export const dynamic = "force-dynamic";

export default async function BrandsPage() {
  const { supabase } = await requireAdmin();
  const { data, error } = await supabase.from("commercial_brands")
    .select("id,name,slug,category,website_url,country_code,status,source_name,created_at")
    .order("name").limit(500);
  const brands = (data ?? []) as unknown as BrandRow[];
  return <main className="shell">
    <AdminHeader />
    <section className="page-heading">
      <p className="eyebrow">الكتالوج التجاري العالمي</p>
      <h1>دليل المتاجر والعلامات التجارية</h1>
      <p>نسجل العلامات التجارية من الآن، ثم نراجع بياناتها ونربط بها الفروع الحقيقية. اعتماد العلامة في الدليل لا يعني وجود شراكة أو فرع متاح للطلب.</p>
    </section>
    <section className="list-panel">
      <div className="section-heading"><h2>إضافة علامة تجارية</h2><span className="count-chip">{brands.length} علامة</span></div>
      <form action={createCommercialBrand} className="branch-policy-form">
        <div className="branch-policy-grid">
          <label>اسم العلامة<input name="name" required maxLength={120} placeholder="مثال: Marjane" /></label>
          <label>الرابط المختصر<input name="slug" required pattern="[a-z0-9]+(-[a-z0-9]+)*" placeholder="marjane" /></label>
          <label>الفئة<select name="category" defaultValue="general-merchandise">{Object.entries(categoryLabels).map(([key,label])=><option key={key} value={key}>{label}</option>)}</select></label>
          <label>الموقع الرسمي HTTPS<input name="websiteUrl" type="url" placeholder="https://..." /></label>
          <label>بلد المنشأ (رمز حرفين)<input name="countryCode" maxLength={2} placeholder="MA" /></label>
          <label>مصدر التحقق<input name="sourceName" maxLength={120} placeholder="الموقع الرسمي / مصدر مرخص" /></label>
          <label>رابط المصدر<input name="sourceUrl" type="url" placeholder="https://..." /></label>
        </div>
        <button className="branch-policy-save" type="submit">إضافة إلى الكتالوج للمراجعة</button>
      </form>
    </section>
    <section className="list-panel">
      <div className="section-heading"><h2>العلامات المسجلة</h2><span className="count-chip">{brands.length}</span></div>
      {error ? <p className="error-state">تعذر تحميل دليل العلامات. تأكد من تطبيق ترحيل قاعدة البيانات في بيئة الاختبار.</p> :
      brands.length === 0 ? <div className="empty-state">لا توجد علامات بعد. طبّق ترحيلات الكتالوج في بيئة الاختبار.</div> :
      <div className="table-wrap"><table><thead><tr><th>العلامة</th><th>الفئة</th><th>الدولة</th><th>المصدر</th><th>الحالة</th><th>الإجراء</th></tr></thead><tbody>
        {brands.map(brand=><tr key={brand.id}>
          <td><strong>{brand.name}</strong><small style={{display:"block"}}>{brand.website_url ?? brand.slug}</small></td>
          <td>{categoryLabels[brand.category] ?? brand.category}</td>
          <td>{brand.country_code ?? "—"}</td><td>{brand.source_name ?? "—"}</td>
          <td>{statusLabels[brand.status] ?? brand.status}</td>
          <td><form action={updateCommercialBrandStatus} className="inline-policy-status">
            <input type="hidden" name="brandId" value={brand.id} />
            <select name="status" defaultValue={brand.status}>
              <option value="pending_verification">بانتظار المراجعة</option><option value="approved">اعتماد في الدليل</option>
              <option value="rejected">رفض</option><option value="suspended">إيقاف</option><option value="draft">مسودة</option>
            </select>
            <button className="logout-button inline-action" type="submit">حفظ</button>
          </form></td>
        </tr>)}
      </tbody></table></div>}
    </section>
  </main>;
}
