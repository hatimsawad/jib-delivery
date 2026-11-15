"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "../../lib/supabase/client";

export default function LoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError("");
    const supabase = createClient();
    const { error: signInError } = await supabase.auth.signInWithPassword({ email, password });
    setBusy(false);
    if (signInError) { setError("تعذر تسجيل الدخول. تحقق من البريد الإلكتروني وكلمة المرور."); return; }
    router.replace("/");
    router.refresh();
  }

  return <form className="login-form" onSubmit={submit}>
    <label htmlFor="email">البريد الإلكتروني</label>
    <input id="email" type="email" autoComplete="username" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="admin@example.com" />
    <label htmlFor="password">كلمة المرور</label>
    <input id="password" type="password" autoComplete="current-password" required value={password} onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" />
    {error && <p className="form-error" role="alert">{error}</p>}
    <button type="submit" disabled={busy}>{busy ? "جارٍ الدخول…" : "تسجيل الدخول"}</button>
  </form>;
}
