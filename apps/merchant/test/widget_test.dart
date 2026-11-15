import 'package:flutter_test/flutter_test.dart';
import 'package:jib_merchant/main.dart';

void main() {
  testWidgets('merchant home shows store management sections', (tester) async {
    await tester.pumpWidget(const MerchantApp());
    expect(find.text('جيب · التاجر'), findsOneWidget);
    expect(find.text('إدارة المتجر'), findsOneWidget);
    expect(find.text('المنتجات'), findsOneWidget);
  });
}
