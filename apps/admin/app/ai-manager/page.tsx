import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";
import AiManagerChat from "./ai-manager-chat";

export const dynamic = "force-dynamic";

export default async function AiManagerPage() {
  await requireAdmin();
  const providerReady = Boolean(
    process.env.FREELLMAPI_BASE_URL &&
    process.env.FREELLMAPI_API_KEY &&
    process.env.FREELLMAPI_FREE_MODEL
  );

  return (
    <main className="shell">
      <AdminHeader />
      <section className="page-heading">
        <p className="eyebrow">JIB AI MANAGER · FREE MODEL ROUTER</p>
        <h1>مدير الذكاء الاصطناعي</h1>
        <p>مساعد تشغيلي مستقل داخل JIB Manager، يستخدم FreeLLMAPI عبر واجهة OpenAI المتوافقة، مع تعطيل أي تحويل تلقائي إلى نماذج مدفوعة.</p>
      </section>
      <section className="manager-settings-grid">
        <article className="metric"><span>حالة مزود FreeLLMAPI</span><b className="settings-value">{providerReady ? "الإعدادات موجودة" : "بانتظار الربط"}</b><small>لا يعني وجود المتغيرات نجاح اختبار الاتصال</small></article>
        <article className="metric"><span>صلاحيات المساعد</span><b className="settings-value">استشاري فقط</b><small>لا SQL أو أدوات أو تعديل تلقائي</small></article>
        <article className="metric"><span>سياسة التكلفة</span><b className="settings-value">مجاني فقط</b><small>يتوقف عند نفاد الحصة</small></article>
      </section>
      <AiManagerChat />
      <p className="manager-provider-note">
        يتطلب الربط إضافة FREELLMAPI_BASE_URL وFREELLMAPI_API_KEY وFREELLMAPI_FREE_MODEL إلى إعدادات Vercel كمتغيرات خادم سرية. يجب استضافة FreeLLMAPI على HTTPS مع حفظ مفاتيح المزودين بأمان. المشروع الأساسي لـ FreeLLMAPI يصف نفسه بأنه للتجربة الشخصية وليس بنية إنتاج مستقرة؛ لا تعتبره جاهزاً للإنتاج قبل مراجعة الاستضافة وشروط المزودين.
      </p>
    </main>
  );
}
