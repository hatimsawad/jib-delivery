import AdminHeader from "../../admin-header";
import { requireAdmin } from "../../admin-data";
type BranchRow={id:string;name:string;address_text:string;city:string;status:string;is_active:boolean;notes:string|null;source_url:string|null};
type BranchClient={from(table:"commercial_brand_branch_templates"):{select(columns:string):{order(column:"city",options:{ascending:boolean}):{limit(n:number):Promise<{data:unknown[]|null;error:{message:string}|null}>}}}};
export const dynamic="force-dynamic";
const statusLabels:Record<string,string>={draft:"مسودة",needs_branch_confirmation:"بانتظار استكمال بيانات التشغيل",ready_for_review:"موافقة الشراكة مسجلة · جاهز للمراجعة التشغيلية",rejected:"مرفوض"};
export default async function BranchTemplatesPage(){
 const {supabase}=await requireAdmin();const client=supabase as unknown as BranchClient;
 const {data,error}=await client.from("commercial_brand_branch_templates").select("id,name,address_text,city,status,is_active,notes,source_url").order("city",{ascending:true}).limit(100);
 const rows=(data??[]) as unknown as BranchRow[];
 return <main className="shell"><AdminHeader/><section className="page-heading"><p className="eyebrow">تحضير الشركاء · الرباط والنواحي</p><h1>قوالب فروع McDonald&apos;s</h1><p>تم تجهيز الفروع السبعة مسبقاً داخل JIB Manager. الموافقة التي أكدتها تشمل الفروع كلها؛ تبقى بيانات التشغيل الخاصة بكل فرع قبل إتاحته للطلب.</p></section>
 <section className="manager-notice"><div><strong>حالة موافقة الشراكة</strong><p>سُجل تأكيدك بأن موافقة المدير تشمل الفروع السبعة. لم نفعّلها في تطبيق الزبون بعد: يلزم تثبيت الأسعار والتوفر وساعات العمل وقناة استقبال الطلبات والعنوان الدقيق لكل فرع، حتى لا يستقبل JIB طلباً لا يستطيع تنفيذه.</p></div><a href="https://www.mcdonalds.ma/nos-restaurants" target="_blank" rel="noreferrer">دليل الفروع الرسمي ↗</a></section>
 <section className="list-panel"><div className="section-heading"><h2>الفروع السبعة المحضّرة</h2><span className="count-chip">{rows.length} فرع</span></div>
 {error?<p className="error-state">تعذر تحميل قائمة الفروع.</p>:<div className="table-wrap"><table><thead><tr><th>الفرع</th><th>المدينة</th><th>العنوان المنشور</th><th>حالة التجهيز</th><th>التفعيل</th><th>المصدر</th></tr></thead><tbody>{rows.map(r=><tr key={r.id}><td><strong>{r.name}</strong></td><td>{r.city}</td><td>{r.address_text}</td><td><span className="status-pill">{statusLabels[r.status]??r.status}</span><small style={{display:"block",maxWidth:320,whiteSpace:"normal"}}>{r.notes}</small></td><td>{r.is_active?"مفعّل":"مخفي عن الزبائن"}</td><td>{r.source_url?<a href={r.source_url} target="_blank" rel="noreferrer">الموقع الرسمي ↗</a>:"—"}</td></tr>)}</tbody></table></div>}</section></main>;
}