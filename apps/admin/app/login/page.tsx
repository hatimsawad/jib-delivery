import LoginForm from "./login-form";

export default function LoginPage() {
  return <main className="login-shell">
    <section className="login-card">
      <div className="login-brand"><span className="mark">J</span><div><strong>جيب JIB</strong><small>لوحة الإدارة</small></div></div>
      <p className="eyebrow">مرحباً بعودتك</p>
      <h1>تسجيل الدخول</h1>
      <p className="login-copy">هذه المساحة مخصصة لفريق إدارة JIB المعتمد.</p>
      <LoginForm />
      <a className="back-link" href="/">العودة إلى لوحة التحكم</a>
    </section>
  </main>;
}
