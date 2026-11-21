import 'package:flutter_test/flutter_test.dart';
import 'package:jib_customer/main.dart';

void main() {
  testWidgets('customer home renders JIB entry points', (tester) async {
    await tester.pumpWidget(const JibCustomerApp());
    expect(find.text('جيب JIB'), findsOneWidget);
    expect(find.text('المتاجر والعلامات التجارية'), findsOneWidget);
    expect(find.text('طلباتي'), findsOneWidget);
  });
}
