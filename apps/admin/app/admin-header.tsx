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
        <Link href="/settings/notifications">إعدادات AI Manager</Link>
      </nav>
    </>
  );
}
