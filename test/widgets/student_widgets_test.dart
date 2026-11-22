import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/widgets/student_widgets.dart';

void main() {
  group('initialsOf', () {
    test('two names → two initials', () {
      expect(initialsOf('nawaf ahmed'), 'NA');
    });

    test('one name → one initial', () {
      expect(initialsOf('Khalid'), 'K');
    });

    test('three names → only first two', () {
      expect(initialsOf('Samir Ali Hassan'), 'SA');
    });

    test('extra spaces are ignored', () {
      expect(initialsOf('  Jules   Verne  '), 'JV');
    });

    test('empty name does not crash', () {
      expect(initialsOf(''), '');
      expect(initialsOf('   '), '');
    });
  });

  group('lastAssessedLabel', () {
    test('null → not assessed', () {
      expect(lastAssessedLabel(null), 'Not assessed yet');
    });

    test('today', () {
      expect(lastAssessedLabel(DateTime.now()), 'Last assessed today');
    });

    test('yesterday', () {
      final d = DateTime.now().subtract(const Duration(days: 1));
      expect(lastAssessedLabel(d), 'Last assessed yesterday');
    });

    test('several days ago', () {
      final d = DateTime.now().subtract(const Duration(days: 5));
      expect(lastAssessedLabel(d), 'Last assessed 5d ago');
    });
  });

  test('every status has a label', () {
    expect(SupportStatus.onTrack.label, 'On track');
    expect(SupportStatus.watch.label, 'Watch');
    expect(SupportStatus.needsSupport.label, 'Needs support');
  });
}
