import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/core/date_labels.dart';

void main() {
  final now = DateTime(2026, 11, 10, 12);

  test('labels a check from today with the time', () {
    expect(
      checkTimeLabel(DateTime(2026, 11, 10, 8, 30), now: now),
      'Today, 8:30 AM',
    );
  });

  test('labels yesterday and older dates', () {
    expect(checkTimeLabel(DateTime(2026, 11, 9, 15), now: now), 'Yesterday');
    expect(checkTimeLabel(DateTime(2026, 11, 2, 9), now: now), 'Nov 2');
  });
}
