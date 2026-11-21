import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "JIB Manager | مركز الإدارة والتشغيل", description: "مركز الإدارة والتشغيل المستقل لمنصة جيب للتوصيل في المغرب" };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="ar" dir="rtl"><body>{children}</body></html>;
}
