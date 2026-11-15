import LoginForm from "./login-form";

type LoginPageProps = {
  searchParams: Promise<{ passwordUpdated?: string; denied?: string }>;
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const params = await searchParams;

  return <main className="login-shell">
    <section className="login-card">
      <div className="login-brand"><span className="mark">J</span><div><strong>جيب JIB</strong><small>لوحة الإدارة</small></div></div>
      <p className="eyebrow">مرحباً بعودتك</p>
      <h1>تسجيل الدخول</h1>
      <p className="login-copy">هذه المساحة مخصصة لفريق إدارة JIB المعتمد.</p>
      {params.passwordUpdated === "1" && <p className="form-success" role="status">تم تحديث كلمة المرور بنجاح. سجّل الدخول بكلمة المرور الجديدة.</p>}
      {params.denied === "1" && <p className="form-error" role="alert">هذا الحساب لا يملك صلاحية إدارة منصة JIB.</p>}
      <LoginForm />
      <a className="back-link" href="/">العودة إلى لوحة التحكم</a>
    </section>
  </main>;
}
