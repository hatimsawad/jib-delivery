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

  testWidgets('customer app renders catalog and ordering entry points', (tester) async {
    await tester.pumpWidget(const JibCustomerApp());
    expect(find.text('جيب JIB'), findsOneWidget);
    expect(find.text('العلامات التجارية'), findsOneWidget);
    expect(find.text('فروع تستقبل الطلبات'), findsOneWidget);
  });
}
