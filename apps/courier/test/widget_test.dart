import 'package:flutter_test/flutter_test.dart';
import 'package:jib_courier/main.dart';

void main() {
  testWidgets('courier home shows initial offline state', (tester) async {
    await tester.pumpWidget(const CourierApp());
    expect(find.text('جيب · السائق'), findsOneWidget);
    expect(find.text('غير متصل حالياً'), findsOneWidget);
  });
}
