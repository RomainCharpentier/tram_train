import 'package:flutter_test/flutter_test.dart';
import 'package:train_qil/domain/services/clock_service.dart';

void main() {
  group('SystemClockService', () {
    test('now returns current time close to DateTime.now()', () {
      final clock = SystemClockService();
      final before = DateTime.now();
      final now = clock.now();
      final after = DateTime.now();

      expect(now.isAfter(before) || now.isAtSameMomentAs(before), isTrue);
      expect(after.isAfter(now) || after.isAtSameMomentAs(now), isTrue);
    });
  });

  group('MockClockService', () {
    test('returns fixed DateTime provided at construction', () {
      final fixed = DateTime(2025, 1, 1, 12, 30);
      final clock = MockClockService(fixed);

      expect(clock.now(), fixed);
    });
  });
}
