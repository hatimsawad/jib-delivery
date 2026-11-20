import AdminHeader from "../admin-header";
import { requireAdmin } from "../admin-data";
type TemplateRow = { id:string; name:string; category:string; status:string; price_mad:number|null; is_active:boolean; official_source_url:string|null; notes:string|null; commercial_brands:{name:string}|null };
type CatalogClient = { from(table:"commercial_brand_product_templates"):{ select(columns:string):{ order(column:"category",options:{ascending:boolean}):{limit(count:number):Promise<{data:unknown[]|null;error:{message:string}|null}>} } } };
const labels:Record<string,string>={sharing:"للمشاركة",menus:"الوجبات",burgers:"البرغر",wraps:"الراب","happy-meal":"هابي ميل","duo-mabrouk":"ديو مبروك","menu-mabrouk":"منيو مبروك",desserts:"الحلويات والمثلجات",drinks:"المشروبات",fries:"البطاطس",sauces:"الصلصات",salads:"السلطات",breakfast:"الفطور",mccafe:"McCafé"};
export const dynamic="force-dynamic";
export default async function CatalogPage(){
 const {supabase}=await requireAdmin(); const client=supabase as unknown as CatalogClient;
 const {data,error}=await client.from("commercial_brand_product_templates").select("id,name,category,status,price_mad,is_active,official_source_url,notes,commercial_brands(name)").order("category",{ascending:true}).limit(300);
 const items=(data??[]) as unknown as TemplateRow[];
 return <main className="shell"><AdminHeader/>
 <section className="page-heading"><p className="eyebrow">كتالوج المنتجات المسبق</p><h1>قوالب المنتجات الجاهزة للمراجعة</h1><p>تُجهّز كتالوجات العلامات مسبقاً هنا لتسريع الانضمام. حالياً يحتوي هذا السجل على أصناف McDonald's Maroc؛ وتُضاف بقية العلامات والمنتجات إلى القالب نفسه قبل تفعيلها.</p></section>
 <section className="manager-notice"><div><strong>قاعدة الإظهار في تطبيق الزبون</strong><p>المنتج لا يظهر إلا بعد ربطه بفرع فعلي معتمد، وتحديد سعره وتوفره وصورته، ثم تفعيل الفرع والمنتج. المسودات لا تدخل في البحث أو السلة أو الطلبات.</p></div><a href="https://www.mcdonalds.ma/new/plan-du-site" target="_blank" rel="noreferrer">كتالوج McDonald's الرسمي ↗</a></section>
 <section className="list-panel"><div className="section-heading"><h2>قوالب McDonald's Maroc</h2><span className="count-chip">{items.length} قالب منتج</span></div>
 {error?<p className="error-state">تعذر تحميل قوالب المنتجات. تحقق من ترحيل قاعدة البيانات وصلاحيات الإدارة.</p>:items.length===0?<div className="empty-state">لا توجد قوالب منتجات مسجلة.</div>:
 <div className="table-wrap"><table><thead><tr><th>المنتج</th><th>الفئة</th><th>العلامة</th><th>السعر</th><th>الحالة</th><th>المصدر</th></tr></thead><tbody>
 {items.map(item=><tr key={item.id}><td><strong>{item.name}</strong><small style={{display:"block",color:"#888"}}>{item.notes}</small></td><td>{labels[item.category]??item.category}</td><td>{item.commercial_brands?.name??"—"}</td><td>{item.price_mad===null?"غير محدد":item.price_mad+" د.م"}</td><td><span className="status-pill">{item.is_active?"مفعّل":item.status==="ready_for_review"?"جاهز للمراجعة":"مسودة · غير منشور"}</span></td><td>{item.official_source_url?<a href={item.official_source_url} target="_blank" rel="noreferrer">المصدر ↗</a>:"—"}</td></tr>)}
 </tbody></table></div>}</section></main>;
}