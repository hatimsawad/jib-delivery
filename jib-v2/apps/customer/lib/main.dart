import 'package:material_ui/material_ui.dart';

void main() => runApp(const JibCustomerApp());

class JibCustomerApp extends StatelessWidget {
  const JibCustomerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'JIB',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF111827)),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const CustomerHome(),
      );
}

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            title: const Text('جيب JIB', style: TextStyle(fontWeight: FontWeight.w800)),
            centerTitle: false,
            backgroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              Text('كل ما تحتاجه، يصلك لبابك', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('اكتشف المتاجر والمنتجات القريبة منك في الرباط وتمارة.'),
              const SizedBox(height: 24),
              const Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.storefront_outlined, size: 34),
                    SizedBox(height: 12),
                    Text('المتاجر والعلامات التجارية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('سيظهر هنا دليل المتاجر والمنتجات بعد ربط بيئة JIB V2 الآمنة.'),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              const Card(child: ListTile(leading: Icon(Icons.receipt_long), title: Text('طلباتي'), subtitle: Text('تتبع طلباتك ومراحل التوصيل'))),
              const Card(child: ListTile(leading: Icon(Icons.location_on_outlined), title: Text('عناويني'), subtitle: Text('إدارة عناوين التوصيل'))),
              const SizedBox(height: 18),
              const Text('نسخة تأسيسية — لا تستقبل طلبات حقيقية حالياً.', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
