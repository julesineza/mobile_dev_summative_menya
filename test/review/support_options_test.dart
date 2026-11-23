import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/core/support_options.dart';

void main() {
  group('oneWeekFrom', () {
    test('adds seven days and drops the time of day', () {
      final result = oneWeekFrom(DateTime(2026, 9, 23, 14, 30));
      expect(result, DateTime(2026, 9, 30));
    });

    test('rolls over month ends', () {
      expect(oneWeekFrom(DateTime(2026, 12, 28)), DateTime(2027, 1, 4));
    });
  });

  group('isValidRecheckDate', () {
    final now = DateTime(2026, 9, 23, 10);

    test('today is allowed', () {
      expect(isValidRecheckDate(DateTime(2026, 9, 23), now: now), isTrue);
    });

    test('a past day is rejected', () {
      expect(isValidRecheckDate(DateTime(2026, 9, 22), now: now), isFalse);
    });

    test('a future day is allowed', () {
      expect(isValidRecheckDate(DateTime(2026, 10, 1), now: now), isTrue);
    });
  });

  group('SupportActivity', () {
    test('round-trips through its stored name', () {
      for (final a in SupportActivity.values) {
        expect(SupportActivity.fromStorage(a.storageName), a);
      }
    });

    test('unknown stored value gives null', () {
      expect(SupportActivity.fromStorage('something else'), isNull);
    });
  });

  test('formatPlanDate uses day, short month, year', () {
    expect(formatPlanDate(DateTime(2026, 9, 30)), '30 Sep 2026');
  });
}
