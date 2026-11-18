import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";
import ImageGenerator from "./image-generator";

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
        <p>صور أطباق حسب المكونات والوصف، وأغلفة مقالات حسب الفكرة. كل صورة مولدة تحمل وسم AI وتحتاج موافقة بشرية قبل النشر.</p>
      </section>
      {error ? (
        <p className="error-state">تعذر تحميل طلبات الصور. تحقق من صلاحيات المدير واتصال قاعدة البيانات.</p>
      ) : (
        <ImageGenerator initialJobs={(data ?? []) as never} />
      )}
      <p className="manager-provider-note">الموديل: Black Forest Labs FLUX 3 Image عبر Vercel AI Gateway. التكلفة التقديرية 0.02 دولار للصورة، مع حد أقصى 100 طلب شهرياً. يعتمد الاستخدام على رصيد AI Gateway المتاح في حساب Vercel.</p>
    </main>
  );
}
