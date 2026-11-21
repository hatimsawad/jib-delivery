"use client";

import { useState } from "react";

export default function AiManagerChat() {
  const [message, setMessage] = useState("");
  const [answer, setAnswer] = useState("");
  const [model, setModel] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function send() {
    if (!message.trim() || busy) return;
    setBusy(true); setError(""); setAnswer(""); setModel("");
    try {
      const response = await fetch("/api/ai/manager/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message }),
      });
      const result = await response.json() as { answer?: string; model?: string; error?: string };
      if (!response.ok) throw new Error(result.error ?? "تعذر الاتصال بالمساعد.");
      setAnswer(result.answer ?? "");
      setModel(result.model ?? "");
    } catch (e) {
      setError(e instanceof Error ? e.message : "تعذر تنفيذ الطلب.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="list-panel">
      <div className="section-heading"><h2>مساعد JIB AI Manager</h2><span className="count-chip">FreeLLMAPI · مجاني فقط</span></div>
      <p className="manager-provider-note">
        المساعد استشاري فقط ولا يملك صلاحية تعديل قاعدة البيانات أو الطلبات أو الأسعار أو النشر. لا ترسل كلمات مرور أو مفاتيح أو بيانات شخصية أو مواقع دقيقة.
      </p>
      <label htmlFor="jib-ai-message">اكتب سؤالك أو المهمة</label>
      <textarea
        id="jib-ai-message"
        className="manager-ai-input"
        rows={5}
        maxLength={6000}
        value={message}
        onChange={(event) => setMessage(event.target.value)}
        placeholder="مثال: حلّل حالة الطلبات واقترح خطوات تشغيلية دون تغيير القرارات المعتمدة..."
      />
      <div className="section-heading">
        <small>{message.length}/6000</small>
        <button className="manager-ai-send" type="button" disabled={busy || !message.trim()} onClick={send}>
          {busy ? "جارٍ الاتصال..." : "إرسال إلى المساعد"}
        </button>
      </div>
      {error && <p className="error-state" role="alert">{error}</p>}
      {answer && (
        <article className="manager-event manager-event-info">
          <div className="manager-event-heading"><strong>إجابة المساعد</strong><span>{model}</span></div>
          <p style={{ whiteSpace: "pre-wrap" }}>{answer}</p>
        </article>
      )}
    </section>
  );
}
