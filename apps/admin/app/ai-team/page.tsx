import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";
import AITeamPanel from "./team-panel";

export const dynamic = "force-dynamic";

export default async function AITeamPage() {
  await requireAdmin();
  return (
    <main className="shell">
      <AdminHeader />
      <section className="page-heading">
        <p className="eyebrow">JIB AI MANAGER · MULTI-MODEL TEAM</p>
        <h1>فريق الذكاء الاصطناعي</h1>
        <p>تحليل مستقل من أدوار متخصصة، مع إبقاء القرار النهائي والموافقة على التنفيذ بيدك.</p>
      </section>
      <AITeamPanel />
    </main>
  );
}
