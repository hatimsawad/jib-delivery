import Link from "next/link";
import LogoutButton from "./logout-button";

export default function AdminHeader() {
  return <>
    <header className="topbar">
      <Link href="/" className="brand brand-link"><span className="mark">J</span><span><strong>JIB Manager</strong><small>مركز الإدارة والتشغيل · الرباط</small></span></Link>
      <div className="top-actions"><span className="status">دخول إداري موثّق</span><LogoutButton /></div>
    </header>
    <nav className="admin-nav" aria-label="التنقل الرئيسي">
      <Link href="/">الرئيسية</Link><Link href="/stores">المتاجر والمطاعم</Link><Link href="/brands">دليل العلامات</Link><Link href="/catalog">قوالب المنتجات</Link><Link href="/catalog/branches">قوالب الفروع</Link><Link href="/orders">الطلبات</Link><Link href="/products">المنتجات الفعلية</Link><Link href="/users">المستخدمون والمندوبون</Link>
      <details className="admin-more"><summary>أدوات الإدارة</summary><div className="admin-more-menu">
        <Link href="/tracking">تتبع المندوبين</Link><Link href="/monitoring">المراقبة والحوادث</Link><Link href="/ai-manager">JIB AI Manager</Link><Link href="/images">استوديو الصور</Link><Link href="/settings/notifications">إعدادات الإشعارات</Link>
      </div></details>
    </nav>
  </>;
}