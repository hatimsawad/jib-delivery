"use client";

import { useState } from "react";
import { createClient } from "../../lib/supabase/client";

export default function ForgotPasswordForm() {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setMessage("");
    setError("");
    const supabase = createClient();
    const redirectTo = new URL("/auth/callback?next=/update-password", window.location.origin).toString();
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(email.trim(), { redirectTo });
    setBusy(false);
    if (resetError) {
      setError("تعذر إرسال رابط الاستعادة الآن. حاول لاحقاً أو تحقق من إعدادات البريد.");
      return;
    }
    setMessage("إذا كان هذا البريد مسجلاً، فسيصلك رابط لاستعادة كلمة المرور. تحقق من صندوق الوارد والبريد غير المرغوب فيه.");
  }

  return <form className="login-form" onSubmit={submit}>
    <label htmlFor="recovery-email">البريد الإلكتروني</label>
    <input id="recovery-email" type="email" autoComplete="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="admin@example.com" />
    {error && <p className="form-error" role="alert">{error}</p>}
    {message && <p className="form-success" role="status">{message}</p>}
    <button type="submit" disabled={busy}>{busy ? "جارٍ الإرسال…" : "إرسال رابط الاستعادة"}</button>
  </form>;
}
