import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";

export const dynamic = "force-dynamic";

export default async function UsersPage() {
  const { supabase } = await requireAdmin();
  const { data, error } = await supabase
    .from("profiles")
    .select("id,full_name,phone,role,created_at")
    .order("created_at", { ascending: false })
    .limit(100);

  const profiles = data ?? [];
  const roles: Record<string, string> = { admin: "إدارة", customer: "زبون", courier: "سائق", merchant: "تاجر" };

  return (
    <main className="shell">
      <AdminHeader />
      <section className="page-heading"><p className="eyebrow">حسابات المنصة</p><h1>المستخدمون</h1><p>قائمة الحسابات حسب أدوارها المسجلة في JIB.</p></section>
      <section className="list-panel">
        <div className="section-heading"><h2>الحسابات</h2><span className="count-chip">{profiles.length} حساب</span></div>
        {error ? <p className="error-state">تعذر تحميل المستخدمين. تحقق من صلاحيات قاعدة البيانات.</p> :
          profiles.length === 0 ? <div className="empty-state"><strong>لا توجد حسابات بعد</strong><span>ستظهر الحسابات بعد التسجيل في المنصة.</span></div> :
          <div className="table-wrap"><table>
            <thead><tr><th>الاسم</th><th>الهاتف</th><th>الدور</th><th>تاريخ التسجيل</th></tr></thead>
            <tbody>{profiles.map((profile) => <tr key={profile.id}>
              <td><strong>{profile.full_name || "مستخدم جديد"}</strong></td><td>{profile.phone || "—"}</td>
              <td><span className={profile.role === "admin" ? "status-pill status-good" : "status-pill"}>{roles[profile.role] ?? profile.role}</span></td>
              <td>{new Date(profile.created_at).toLocaleDateString("ar-MA")}</td>
            </tr>)}</tbody>
          </table></div>}
      </section>
    </main>
  );
}
