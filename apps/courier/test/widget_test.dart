import 'package:flutter_test/flutter_test.dart';
import 'package:jib_courier/main.dart';

void main() {
  test('courier status labels map to Arabic', () {
    expect(courierStatusLabel('ready_for_pickup'), 'جاهز للاستلام');
    expect(courierStatusLabel('delivering'), 'في الطريق إلى الزبون');
  });

  test('courier status transitions only move forward', () {
    expect(nextCourierStatus('ready_for_pickup'), 'picked_up');
    expect(nextCourierStatus('picked_up'), 'delivering');
    expect(nextCourierStatus('delivering'), 'delivered');
    expect(nextCourierStatus('delivered'), isNull);
    expect(nextCourierStatus('pending'), isNull);
  });
}
