import 'package:material_ui/material_ui.dart';

void main() => runApp(const JibMerchantApp());

class JibMerchantApp extends StatelessWidget {
  const JibMerchantApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'JIB Partenaire',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF155E75)), useMaterial3: true),
        home: const MerchantHome(),
      );
}

class MerchantHome extends StatelessWidget {
  const MerchantHome({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('JIB Partenaire')),
          body: ListView(padding: const EdgeInsets.all(20), children: const [
            Text('إدارة متجرك وطلباتك', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Card(child: ListTile(leading: Icon(Icons.inbox_outlined), title: Text('الطلبات الجديدة'), subtitle: Text('ستظهر الطلبات بعد ربط حساب التاجر المعتمد.'))),
            Card(child: ListTile(leading: Icon(Icons.restaurant_menu), title: Text('قيد التحضير'), subtitle: Text('تحديث مراحل تجهيز الطلبات.'))),
            Card(child: ListTile(leading: Icon(Icons.inventory_2_outlined), title: Text('المنتجات والتوفر'), subtitle: Text('إدارة أسعار وتوفر منتجات الفرع.'))),
            SizedBox(height: 12),
            Text('نسخة تأسيسية — لا تدير طلبات حقيقية حالياً.', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
