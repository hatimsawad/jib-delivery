import Link from "next/link";
import LogoutButton from "./logout-button";

export default function AdminHeader() {
  return (
    <>
      <header className="topbar">
        <Link href="/" className="brand brand-link">
          <span className="mark">J</span>
          <span><strong>JIB Manager</strong><small>مركز الإدارة والتشغيل · الرباط</small></span>
        </Link>
        <div className="top-actions">
          <div className="language-options" aria-label="اللغات المعتمدة">
            <span lang="ar" dir="rtl">العربية</span>
            <span lang="fr">Français</span>
            <span lang="en">English</span>
          </div>
          <span className="status">دخول إداري موثّق</span>
          <LogoutButton />
        </div>
      </header>
      <nav className="admin-nav" aria-label="التنقل الرئيسي">
        <Link href="/">مركز القيادة</Link>
        <Link href="/orders">الطلبات</Link>
        <Link href="/stores">المتاجر</Link>
        <Link href="/products">المنتجات</Link>
        <Link href="/users">المستخدمون والمندوبون</Link>
        <Link href="/monitoring">المراقبة والحوادث</Link>
        <Link href="/images">استوديو الصور الذكي</Link>
        <Link href="/settings/notifications">إعدادات AI Manager</Link>
      </nav>
    </>
  );
}
