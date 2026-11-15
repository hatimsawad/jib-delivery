import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";
import UpdatePasswordForm from "./update-password-form";

export default async function UpdatePasswordPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  return <main className="login-shell">
    <section className="login-card">
      <div className="login-brand"><span className="mark">J</span><div><strong>جيب JIB</strong><small>تأمين حساب الإدارة</small></div></div>
      <p className="eyebrow">خطوة أخيرة</p>
      <h1>اختر كلمة مرور جديدة</h1>
      <p className="login-copy">استخدم 8 أحرف على الأقل، واختر كلمة لا تستخدمها في مواقع أخرى.</p>
      <UpdatePasswordForm />
    </section>
  </main>;
}
