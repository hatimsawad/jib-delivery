import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";
import { setCourierActive } from "./actions";

type ProfileRow = {
  id: string; full_name: string | null; phone: string | null; role: string; created_at: string;
};
type CourierRow = {
  user_id: string; phone: string | null; is_active: boolean; created_at: string;
  profiles: { full_name: string | null; phone: string | null } | null;
};

export const dynamic = "force-dynamic";

export default async function UsersPage() {
  const { supabase } = await requireAdmin();
  const [profilesResult, couriersResult] = await Promise.all([
    supabase.from("profiles").select("id,full_name,phone,role,created_at")
      .order("created_at", { ascending: false }).limit(100),
    supabase.from("courier_profiles")
      .select("user_id,phone,is_active,created_at,profiles(full_name,phone)")
      .order("created_at", { ascending: false }).limit(100),
  ]);
  const profiles = (profilesResult.data ?? []) as unknown as ProfileRow[];
  const couriers = (couriersResult.data ?? []) as unknown as CourierRow[];
  const roles: Record<string, string> = { admin: "إدارة", customer: "زبون", courier: "سائق", merchant: "تاجر" };

  return <main className="shell">
    <AdminHeader />
    <section className="page-heading"><p className="eyebrow">حسابات المنصة</p><h1>المستخدمون</h1><p>متابعة الحسابات وطلبات اعتماد السائقين قبل السماح لهم باستلام الطلبات.</p></section>
    <section className="list-panel">
      <div className="section-heading"><h2>حسابات المستخدمين</h2><span className="count-chip">{profiles.length} حساب</span></div>
      {profilesResult.error ? <p className="error-state">تعذر تحميل المستخدمين.</p> :
        profiles.length === 0 ? <div className="empty-state"><strong>لا توجد حسابات بعد</strong><span>ستظهر الحسابات بعد التسجيل في المنصة.</span></div> :
        <div className="table-wrap"><table><thead><tr><th>الاسم</th><th>الهاتف</th><th>الدور</th><th>تاريخ التسجيل</th></tr></thead>
          <tbody>{profiles.map(profile => <tr key={profile.id}>
            <td><strong>{profile.full_name || "مستخدم جديد"}</strong></td><td>{profile.phone || "—"}</td>
            <td><span className={profile.role === "admin" ? "status-pill status-good" : "status-pill"}>{roles[profile.role] ?? profile.role}</span></td>
            <td>{new Date(profile.created_at).toLocaleDateString("ar-MA")}</td>
          </tr>)}</tbody>
        </table></div>}
    </section>
    <section className="list-panel">
      <div className="section-heading"><h2>طلبات اعتماد المندوبين</h2><span className="count-chip">{couriers.length} طلب</span></div>
      {couriersResult.error ? <p className="error-state">تعذر تحميل طلبات اعتماد المندوبين.</p> :
        couriers.length === 0 ? <div className="empty-state"><strong>لا توجد طلبات مندوبين بعد</strong><span>ستظهر هنا حسابات المندوبين الجديدة.</span></div> :
        <div className="table-wrap"><table><thead><tr><th>المندوب</th><th>الهاتف</th><th>الحالة</th><th>الإجراء</th></tr></thead>
          <tbody>{couriers.map(courier => <tr key={courier.user_id}>
            <td><strong>{courier.profiles?.full_name || "مندوب جديد"}</strong></td>
            <td>{courier.phone || courier.profiles?.phone || "—"}</td>
            <td><span className={courier.is_active ? "status-pill status-good" : "status-pill"}>{courier.is_active ? "معتمد ونشط" : "بانتظار الاعتماد"}</span></td>
            <td><form action={setCourierActive}>
              <input type="hidden" name="userId" value={courier.user_id} />
              <input type="hidden" name="isActive" value={String(!courier.is_active)} />
              <button className="logout-button inline-action" type="submit">{courier.is_active ? "تعطيل المندوب" : "اعتماد المندوب"}</button>
            </form></td>
          </tr>)}</tbody>
        </table></div>}
    </section>
  </main>;
}
