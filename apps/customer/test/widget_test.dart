import 'package:flutter_test/flutter_test.dart';
import 'package:jib_customer/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  });

  testWidgets('customer app shows JIB sign-in screen when signed out', (tester) async {
    await tester.pumpWidget(const JibApp());
    await tester.pump();
    expect(find.text('جيب JIB'), findsOneWidget);
    expect(find.text('مرحباً بعودتك'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
