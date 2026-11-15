import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jib_merchant/main.dart';

void main() {
  testWidgets('merchant login screen renders in Arabic', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MerchantLogin(),
      ),
    ));
    expect(find.text('JIB · فضاء التاجر'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
  });
}
