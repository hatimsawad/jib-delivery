import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jib_courier/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://ldgbyshgcifheditplnn.supabase.co',
      publishableKey: 'sb_publishable_wvNMRZTBFX4viI2ypcdWjQ_YBqgi_TV',
    );
  });

  testWidgets('courier app renders secure sign-in entry point', (tester) async {
    await tester.pumpWidget(const JibCourierApp());
    expect(find.text('JIB Livreur'), findsOneWidget);
    expect(find.text('مساحة المندوب'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
