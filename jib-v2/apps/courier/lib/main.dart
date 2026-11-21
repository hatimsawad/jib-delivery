import 'package:material_ui/material_ui.dart';

void main() => runApp(const JibCourierApp());

class JibCourierApp extends StatelessWidget {
  const JibCourierApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'JIB Livreur',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF166534)), useMaterial3: true),
        home: const CourierHome(),
      );
}

class CourierHome extends StatelessWidget {
  const CourierHome({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('JIB Livreur')),
          body: ListView(padding: const EdgeInsets.all(20), children: const [
            Text('مساحة عمل المندوب', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Card(child: ListTile(leading: Icon(Icons.toggle_on_outlined), title: Text('حالة التوفر'), subtitle: Text('تفعيل التوفر بعد تسجيل الدخول والتحقق.'))),
            Card(child: ListTile(leading: Icon(Icons.delivery_dining), title: Text('عروض التوصيل'), subtitle: Text('ستظهر عروض الطلبات المسندة إليك.'))),
            Card(child: ListTile(leading: Icon(Icons.map_outlined), title: Text('المهام النشطة'), subtitle: Text('مراحل الاستلام والتوصيل ومشاركة الموقع بموافقتك.'))),
            SizedBox(height: 12),
            Text('نسخة تأسيسية — لا يوجد تتبع أو استقبال مهام حقيقية حالياً.', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
