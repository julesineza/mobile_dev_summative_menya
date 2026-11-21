import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/core/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty and malformed emails', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('teacher'), 'Enter a valid email address');
      expect(Validators.email('a@b'), 'Enter a valid email address');
    });

    test('accepts a valid email', () {
      expect(Validators.email('teacher@school.rw'), isNull);
    });
  });

  group('Validators.newPassword', () {
    test('requires length, a letter and a number', () {
      expect(Validators.newPassword(''), 'Password is required');
      expect(Validators.newPassword('abc123'), 'Use at least 8 characters');
      expect(
        Validators.newPassword('abcdefgh'),
        'Include a letter and a number',
      );
      expect(Validators.newPassword('abcdefg1'), isNull);
    });
  });

  test('confirmPassword must match the original', () {
    expect(Validators.confirmPassword('x', 'y'), 'Passwords do not match');
    expect(Validators.confirmPassword('same1234', 'same1234'), isNull);
  });
}
