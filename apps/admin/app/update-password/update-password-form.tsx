"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "../../lib/supabase/client";

export default function UpdatePasswordForm() {
  const router = useRouter();
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    if (password.length < 8) { setError("يجب أن تتكون كلمة المرور من 8 أحرف على الأقل."); return; }
    if (password !== confirmPassword) { setError("كلمتا المرور غير متطابقتين."); return; }
    setBusy(true);
    const supabase = createClient();
    const { error: updateError } = await supabase.auth.updateUser({ password });
    if (updateError) {
      setBusy(false);
      setError("تعذر تحديث كلمة المرور. قد يكون رابط الاستعادة منتهياً أو مستعملاً مسبقاً؛ اطلب رابطاً جديداً.");
      return;
    }
    await supabase.auth.signOut();
    setBusy(false);
    router.replace("/login?passwordUpdated=1");
    router.refresh();
  }

  return <form className="login-form" onSubmit={submit}>
    <label htmlFor="new-password">كلمة المرور الجديدة</label>
    <input id="new-password" type="password" autoComplete="new-password" minLength={8} required value={password} onChange={(e) => setPassword(e.target.value)} />
    <label htmlFor="confirm-password">تأكيد كلمة المرور</label>
    <input id="confirm-password" type="password" autoComplete="new-password" minLength={8} required value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} />
    {error && <p className="form-error" role="alert">{error}</p>}
    <button type="submit" disabled={busy}>{busy ? "جارٍ الحفظ…" : "حفظ كلمة المرور الجديدة"}</button>
  </form>;
}
