import { NextResponse } from "next/server";
import { requireAdmin } from "../../admin-data";
import { getEnabledFreeTeamModels, runTeamAnalysis } from "../../../../lib/ai/team/orchestrator";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const maxDuration = 60;

export async function POST(request: Request) {
  // Authentication and role authorization are enforced on the server.
  await requireAdmin();

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "INVALID_JSON" }, { status: 400 });
  }

  const task = body && typeof body === "object" ? (body as { task?: unknown }).task : undefined;
  if (typeof task !== "string" || task.trim().length < 10 || task.length > 6_000) {
    return NextResponse.json({ error: "TASK_MUST_BE_10_TO_6000_CHARACTERS" }, { status: 400 });
  }

  const models = getEnabledFreeTeamModels();
  if (models.length === 0) {
    return NextResponse.json({
      status: "not_configured",
      message: "لا توجد نماذج مجانية معتمدة ومفعّلة. لم يتم إرسال أي طلب إلى مزود خارجي.",
      results: [],
    }, { status: 503 });
  }

  try {
    const results = await runTeamAnalysis(task.trim(), models);
    return NextResponse.json({
      status: results.some((item) => item.status === "completed") ? "completed" : "unavailable",
      policy: "free_only_no_paid_fallback",
      results,
      summary: {
        completed: results.filter((item) => item.status === "completed").length,
        failed: results.filter((item) => item.status === "failed").length,
        consensus: "not_inferred",
        note: "تعرض النتائج مستقلة؛ لا تُعتبر موافقة النماذج دليلاً على صحة النتيجة.",
      },
    }, { status: results.some((item) => item.status === "completed") ? 200 : 503 });
  } catch (error) {
    if (error instanceof Error && error.message === "PROVIDER_NOT_CONFIGURED") {
      return NextResponse.json({ status: "not_configured", message: "بوابة النماذج غير مهيأة؛ لم يتم إرسال أي طلب.", results: [] }, { status: 503 });
    }
    return NextResponse.json({ error: "TEAM_ANALYSIS_FAILED" }, { status: 500 });
  }
}
