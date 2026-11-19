import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";
import ImageGenerator, { type ImageJob } from "./image-generator";

export const dynamic = "force-dynamic";

export default async function ImagesPage() {
  const { supabase } = await requireAdmin();
  const { data, error } = await supabase
    .from("jib_ai_manager_image_jobs")
    .select("id,request_type,title,description,status,generated_image_url,estimated_cost_usd,created_at,error_message")
    .order("created_at", { ascending: false })
    .limit(30);

  return (
    <main className="shell">
      <AdminHeader />
      <section className="page-heading">
        <p className="eyebrow">JIB AI MANAGER · IMAGE STUDIO</p>
        <h1>استوديو الصور الذكي</h1>
        <p>التوليد بالذكاء الاصطناعي مخصص حالياً لأغلفة المقالات فقط. صور المنتجات يجب أن تكون صوراً أصلية من التاجر أو المورد حتى لا نعرض صورة لا تطابق السلعة الحقيقية.</p>
      </section>
      {error ? (
        <p className="error-state">تعذر تحميل طلبات الصور. تحقق من صلاحيات المدير واتصال قاعدة البيانات.</p>
      ) : (
        <ImageGenerator initialJobs={(data ?? []) as unknown as ImageJob[]} />
      )}
      <p className="manager-provider-note">الموديل: Black Forest Labs FLUX.1 Schnell عبر Cloudflare Workers AI لأغلفة المقالات فقط. يخضع الاستخدام لحصة وخطة Cloudflare الفعلية؛ لا يقوم JIB بترقية الخطة أو تفعيل الفوترة، وتتوقف الخدمة عند عدم توفر الحصة المجانية.</p>
    </main>
  );
}
