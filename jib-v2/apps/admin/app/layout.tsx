import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "JIB — لوحة الإدارة",
  description: "لوحة تشغيل JIB الخاصة",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ar" dir="rtl">
      <body style={{ margin: 0, fontFamily: "Tahoma, Arial, sans-serif", background: "#F4F1E8", color: "#17251D" }}>
        {children}
      </body>
    </html>
  );
}
