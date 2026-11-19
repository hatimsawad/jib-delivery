"use client";

import { useState } from "react";

type Result = {
  role: string;
  model: string;
  status: "completed" | "failed";
  answer?: string;
  error?: string;
};

const roleLabels: Record<string, string> = {
  architect: "المهندس المعماري",
  implementer: "مختص التنفيذ",
  security: "مراجع الأمان",
  qa: "مهندس الاختبارات",
};

export default function AITeamPanel() {
  const [task, setTask] = useState("");
  const [results, setResults] = useState<Result[]>([]);
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setMessage("");
    setResults([]);
    try {
      const response = await fetch("/api/ai/team", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ task }),
      });
      const payload = await response.json() as {
        message?: string;
        results?: Result[];
        status?: string;
      };
      setResults(payload.results ?? []);
      setMessage(payload.message ?? (response.ok
        ? "اكتمل التحليل. راجع نتائج كل دور بشكل مستقل."
        : "لم يكتمل التحليل. راجع حالة الإعداد والحصة المجانية."));
    } catch {
      setMessage("تعذر الاتصال بالخادم. لم يتم تأكيد إرسال المهمة.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <section className="list-panel">
        <h2>إرسال مهمة للتحليل</h2>
        <p className="manager-provider-note">لا تضع كلمات مرور أو مفاتيح API أو بيانات زبائن أو معلومات شخصية في المهمة. النتائج اقتراحات للمراجعة فقط، ولا تنفذ تغييرات على المشروع.</p>
        <form className="image-request-form" onSubmit={submit}>
          <label htmlFor="team-task">المهمة أو المشكلة</label>
          <textarea id="team-task" value={task} onChange={(event) => setTask(event.target.value)} minLength={10} maxLength={6000} required placeholder="اكتب المهمة التي تريد من فريق JIB تحليلها..." />
          <small>{task.length}/6000 حرف</small>
          <button type="submit" disabled={busy || task.trim().length < 10}>{busy ? "جارٍ التحليل..." : "ابدأ تحليل المهمة"}</button>
        </form>
        {message && <p className={results.length ? "success-state" : "manager-provider-note"} role="status">{message}</p>}
      </section>
      {results.length > 0 && (
        <section className="list-panel">
          <div className="section-heading"><h2>نتائج الفريق</h2><span className="count-chip">{results.filter((item) => item.status === "completed").length} مكتملة</span></div>
          <div className="manager-event-list">
            {results.map((item, index) => (
              <article className="manager-event" key={item.role + item.model + index}>
                <div className="manager-event-heading">
                  <strong>{roleLabels[item.role] ?? item.role}</strong>
                  <span>{item.status === "completed" ? "اكتمل" : "تعذر"}</span>
                </div>
                <small>{item.model}</small>
                {item.answer ? <p style={{ whiteSpace: "pre-wrap" }}>{item.answer}</p> : <p>{item.error ?? "خطأ غير محدد"}</p>}
              </article>
            ))}
          </div>
        </section>
      )}
    </>
  );
}
