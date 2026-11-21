import 'package:flutter_test/flutter_test.dart';
import 'package:jib_courier/main.dart';

void main() {
  testWidgets('courier home renders work sections', (tester) async {
    await tester.pumpWidget(const JibCourierApp());
    expect(find.text('JIB Livreur'), findsOneWidget);
    expect(find.text('عروض التوصيل'), findsOneWidget);
    expect(find.text('المهام النشطة'), findsOneWidget);
  });
}
