import 'package:flutter_test/flutter_test.dart';
import 'package:jib_customer/main.dart';

void main() {
  testWidgets('customer home shows JIB brand and discovery', (tester) async {
    await tester.pumpWidget(const JibApp());
    expect(find.text('جيب JIB'), findsOneWidget);
    expect(find.text('اكتشف الفئات'), findsOneWidget);
    expect(find.text('اختيارات قريبة منك'), findsOneWidget);
  });
}
