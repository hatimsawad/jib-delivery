"use client";

import { useState } from "react";
import { createClient } from "../../lib/supabase/client";

export type ImageJob = {
  id: string;
  request_type: string;
  title: string;
  description: string;
  status: string;
  generated_image_url: string | null;
  estimated_cost_usd: number | null;
  created_at: string;
  error_message: string | null;
};

const statusLabels: Record<string, string> = {
  generating: "قيد الإنشاء",
  ready_for_review: "بانتظار المراجعة",
  approved: "معتمدة",
  rejected: "مرفوضة",
  failed: "فشل الإنشاء",
};

export default function ImageGenerator({ initialJobs }: { initialJobs: ImageJob[] }) {
  const [jobs, setJobs] = useState(initialJobs);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  async function refreshJobs() {
    const supabase = createClient();
    const { data } = await supabase
      .from("jib_ai_manager_image_jobs")
      .select("id,request_type,title,description,status,generated_image_url,estimated_cost_usd,created_at,error_message")
      .order("created_at", { ascending: false })
      .limit(30);
    if (data) setJobs(data as ImageJob[]);
  }

  async function generateArticleCover(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError("");
    setSuccess("");
    try {
      const supabase = createClient();
      const { data: sessionData } = await supabase.auth.getSession();
      const token = sessionData.session?.access_token;
      if (!token) throw new Error("انتهت جلسة الدخول. سجّل الدخول مجدداً.");

      const response = await fetch("/api/ai/generate-image", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ type: "article", title, description }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.error ?? "تعذر إنشاء الصورة.");

      setSuccess("تم إنشاء غلاف المقال. راجعه ثم اعتمده قبل استخدامه.");
      setTitle("");
      setDescription("");
      await refreshJobs();
    } catch (e) {
      setError(e instanceof Error ? e.message : "تعذر إنشاء الصورة.");
    } finally {
      setBusy(false);
    }
  }

  async function review(jobId: string, approve: boolean) {
    setError("");
    setSuccess("");
    const supabase = createClient();
    const { error: reviewError } = await supabase.rpc("jib_ai_manager_review_image_job", {
      p_job_id: jobId,
      p_approve: approve,
    });
    if (reviewError) {
      setError(approve ? "تعذر اعتماد الصورة." : "تعذر رفض الصورة.");
      return;
    }
    setSuccess(approve ? "تم اعتماد الصورة." : "تم رفض الصورة ولم تُنشر.");
    await refreshJobs();
  }

  return (
    <div className="image-manager">
      <section className="list-panel">
        <div className="section-heading"><h2>إنشاء غلاف مقال</h2><span className="count-chip">AI · 16:9</span></div>
        <p className="manager-provider-note">اكتب عنوان المقال وملخصه. سيُنشئ JIB صورة تحريرية مناسبة، ثم يعرضها للمراجعة قبل اعتمادها. الحد الحالي 100 طلب صورة شهرياً.</p>
        <form className="image-request-form" onSubmit={generateArticleCover}>
          <label htmlFor="article-title">عنوان المقال</label>
          <input id="article-title" value={title} onChange={(event) => setTitle(event.target.value)} maxLength={160} required placeholder="مثال: أفضل أطباق المطبخ المغربي في الرباط" />
          <label htmlFor="article-description">ملخص المقال والفكرة الرئيسية</label>
          <textarea id="article-description" value={description} onChange={(event) => setDescription(event.target.value)} maxLength={2000} rows={4} required placeholder="اكتب الفكرة والمكونات أو المشاهد التي تريد ظهورها في الغلاف..." />
          <button type="submit" disabled={busy}>{busy ? "جارٍ إنشاء الغلاف..." : "إنشاء صورة المقال"}</button>
        </form>
        {error && <p className="error-state" role="alert">{error}</p>}
        {success && <p className="success-state" role="status">{success}</p>}
      </section>

      <section className="list-panel">
        <div className="section-heading"><h2>طلبات الصور الأخيرة</h2><span className="count-chip">{jobs.length} طلب</span></div>
        {jobs.length === 0 ? (
          <div className="empty-state"><strong>لا توجد صور مولدة بعد</strong><span>ستظهر هنا صور المقالات والمنتجات بعد طلب إنشائها.</span></div>
        ) : (
          <div className="image-job-grid">
            {jobs.map((job) => (
              <article className="image-job-card" key={job.id}>
                {job.generated_image_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={job.generated_image_url} alt={`صورة مولدة: ${job.title}`} />
                ) : (
                  <div className="image-job-placeholder">لا توجد صورة بعد</div>
                )}
                <div className="image-job-copy">
                  <div className="image-job-title"><strong>{job.title}</strong><span className="ai-image-badge">AI GENERATED</span><span className="status-pill">{statusLabels[job.status] ?? job.status}</span></div>
                  <p>{job.request_type === "article" ? "غلاف مقال" : "صورة منتج"} · {new Date(job.created_at).toLocaleString("ar-MA", { timeZone: "Africa/Casablanca" })}</p>
                  {job.estimated_cost_usd != null && <small>التكلفة التقديرية: ${job.estimated_cost_usd.toFixed(3)}</small>}
                  {job.error_message && <small className="form-error">{job.error_message}</small>}
                  {job.status === "ready_for_review" && (
                    <div className="image-job-actions">
                      <button type="button" onClick={() => review(job.id, true)}>اعتماد الصورة</button>
                      <button type="button" className="secondary-button" onClick={() => review(job.id, false)}>رفض</button>
                    </div>
                  )}
                  {job.status === "approved" && job.generated_image_url && (
                    <a href={job.generated_image_url} target="_blank" rel="noreferrer">فتح الصورة المعتمدة ↗</a>
                  )}
                </div>
              </article>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
