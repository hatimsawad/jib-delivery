import 'package:flutter_test/flutter_test.dart';
import 'package:jib_merchant/main.dart';

void main() {
  testWidgets('merchant home renders operational sections', (tester) async {
    await tester.pumpWidget(const JibMerchantApp());
    expect(find.text('JIB Partenaire'), findsOneWidget);
    expect(find.text('الطلبات الجديدة'), findsOneWidget);
    expect(find.text('المنتجات والتوفر'), findsOneWidget);
  });
}
