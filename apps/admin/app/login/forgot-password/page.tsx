import ForgotPasswordForm from "../forgot-password-form";

export default function ForgotPasswordPage() {
  return <main className="login-shell">
    <section className="login-card">
      <div className="login-brand"><span className="mark">J</span><div><strong>جيب JIB</strong><small>استعادة حساب الإدارة</small></div></div>
      <p className="eyebrow">استعادة الوصول</p>
      <h1>نسيت كلمة المرور؟</h1>
      <p className="login-copy">أدخل بريد حسابك وسنرسل إليك رابطاً آمناً لاختيار كلمة مرور جديدة.</p>
      <ForgotPasswordForm />
      <a className="back-link" href="/login">العودة إلى تسجيل الدخول</a>
    </section>
  </main>;
}
