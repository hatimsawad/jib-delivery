# JIB — جيب

جيب · كلشي قريب ليك

منصة توصيل متعددة الفئات تنطلق من الرباط، المغرب، وتجمع الزبائن والمتاجر والمطاعم والسائقين.

## مكونات المشروع
- apps/customer — تطبيق الزبون
- apps/courier — تطبيق السائق
- apps/merchant — تطبيق التاجر
- apps/admin — لوحة الإدارة
- backend — خدمات الخادم وواجهات API
- supabase — قاعدة البيانات وسياسات الوصول
- docs — مواصفات المشروع وخطة التنفيذ

## الهوية البصرية
- الأحمر: #E31E24
- الأخضر: #00843D
- الأبيض والأسود لونان مساعدان

## نطاق النسخة الأولى
إطلاق تجريبي في الرباط، مع المطاعم والبقالة والمتاجر المحلية. يبدأ الدفع نقداً عند التسليم، وتضاف وسائل الدفع الإلكتروني بعد التعاقد والاختبار.

## حالة المشروع
هذا المستودع هو نقطة الانطلاق. وجود الملفات والوثائق لا يعني أن التطبيق منشور أو جاهز للإنتاج.

راجع docs/PRODUCT_SPEC.md و docs/ARCHITECTURE.md و docs/ROADMAP.md.


## Application workspaces

- `apps/customer`: Flutter customer app starter (Arabic RTL home/discovery screen).
- `apps/courier`: Flutter courier app starter.
- `apps/merchant`: Flutter merchant app starter.
- `apps/admin`: Next.js Arabic RTL operations dashboard starter.

The mobile screens currently use placeholder/sample data. Authentication, live backend integration, payments, maps, notifications and production builds remain pending. See [implementation status](docs/IMPLEMENTATION_STATUS.md).
