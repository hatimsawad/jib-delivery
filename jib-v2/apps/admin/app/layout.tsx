import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "JIB — لوحة الإدارة",
  description: "لوحة تشغيل JIB الخاصة",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ar" dir="rtl">
      <body style={{ margin: 0, fontFamily: "Arial, sans-serif", background: "#f5f6f8", color: "#172033" }}>
        {children}
      </body>
    </html>
  );
}
