import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jib_customer/main.dart';

void main() {
  testWidgets('customer sign-in screen displays JIB branding and form', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: LoginScreen(),
      ),
    ));
    expect(find.text('جيب JIB'), findsOneWidget);
    expect(find.text('مرحباً بعودتك'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('ليس لديك حساب؟ أنشئ حساباً'), findsOneWidget);
  });
}
