import AdminHeader from "../../admin-header";
import { requireAdmin } from "../../admin-data";
type BranchRow={id:string;name:string;address_text:string;city:string;status:string;is_active:boolean;notes:string|null;source_url:string|null};
type BranchClient={from(table:"commercial_brand_branch_templates"):{select(columns:string):{order(column:"city",options:{ascending:boolean}):{limit(n:number):Promise<{data:unknown[]|null;error:{message:string}|null}>}}}};
export const dynamic="force-dynamic";
export default async function BranchTemplatesPage(){
 const {supabase}=await requireAdmin();const client=supabase as unknown as BranchClient;
 const {data,error}=await client.from("commercial_brand_branch_templates").select("id,name,address_text,city,status,is_active,notes,source_url").order("city",{ascending:true}).limit(100);
 const rows=(data??[]) as unknown as BranchRow[];
 return <main className="shell"><AdminHeader/><section className="page-heading"><p className="eyebrow">تحضير الشركاء · الرباط والنواحي</p><h1>فروع McDonald's المرشحة</h1><p>هذه عناوين منشورة في دليل McDonald's Maroc الرسمي، محفوظة كقوالب فقط. ليست فروع JIB ولا تعني موافقة تشغيل كل فرع.</p></section>
 <section className="manager-notice"><div><strong>موافقة المدير التي أفدتَ بها</strong><p>نحتفظ بملف العلامة والمنتجات والفروع للتحضير. يجب تأكيد أن الموافقة تشمل كل فرع وطريقة الطلب قبل تحويل أي قالب إلى متجر حقيقي.</p></div><a href="https://www.mcdonalds.ma/nos-restaurants" target="_blank" rel="noreferrer">دليل الفروع الرسمي ↗</a></section>
 <section className="list-panel"><div className="section-heading"><h2>قوالب الفروع المنشورة</h2><span className="count-chip">{rows.length} فرع مرشح</span></div>
 {error?<p className="error-state">تعذر تحميل قائمة الفروع.</p>:<div className="table-wrap"><table><thead><tr><th>الفرع</th><th>المدينة</th><th>العنوان الرسمي</th><th>الحالة</th><th>المصدر</th></tr></thead><tbody>{rows.map(r=><tr key={r.id}><td><strong>{r.name}</strong></td><td>{r.city}</td><td>{r.address_text}</td><td><span className="status-pill">بانتظار تأكيد الفرع</span></td><td>{r.source_url?<a href={r.source_url} target="_blank" rel="noreferrer">الموقع الرسمي ↗</a>:"—"}</td></tr>)}</tbody></table></div>}</section></main>;
}