import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jib_customer/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://ldgbyshgcifheditplnn.supabase.co',
      publishableKey: 'sb_publishable_wvNMRZTBFX4viI2ypcdWjQ_YBqgi_TV',
    );
  });

  testWidgets('customer app renders premium navigation and shopping entry points', (tester) async {
    await tester.pumpWidget(const JibCustomerApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('JIB'), findsWidgets);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('المتاجر'), findsOneWidget);
    expect(find.text('السلة'), findsOneWidget);
    expect(find.text('طلباتي'), findsOneWidget);
    expect(find.text('كل شي تحبه\nفي مكان واحد'), findsOneWidget);

    await tester.tap(find.text('المتاجر'));
    await tester.pump();
    expect(find.text('المتاجر والمنتجات'), findsOneWidget);
    expect(find.text('اختر فرع الشراء'), findsOneWidget);
  });
}
