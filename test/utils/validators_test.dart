import 'package:flutter_test/flutter_test.dart';
import 'package:connect_call/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('returns error for empty email', () {
        expect(Validators.validateEmail(''), isNotNull);
        expect(Validators.validateEmail(null), isNotNull);
      });

      test('returns error for invalid email', () {
        expect(Validators.validateEmail('invalid'), isNotNull);
        expect(Validators.validateEmail('test@'), isNotNull);
        expect(Validators.validateEmail('@test.com'), isNotNull);
      });

      test('returns null for valid email', () {
        expect(Validators.validateEmail('test@example.com'), isNull);
        expect(Validators.validateEmail('user@domain.co'), isNull);
      });
    });

    group('validatePassword', () {
      test('returns error for empty password', () {
        expect(Validators.validatePassword(''), isNotNull);
        expect(Validators.validatePassword(null), isNotNull);
      });

      test('returns error for short password', () {
        expect(Validators.validatePassword('12345'), isNotNull);
      });

      test('returns null for valid password', () {
        expect(Validators.validatePassword('123456'), isNull);
        expect(Validators.validatePassword('password123'), isNull);
      });
    });

    group('validateName', () {
      test('returns error for empty name', () {
        expect(Validators.validateName(''), isNotNull);
        expect(Validators.validateName(null), isNotNull);
      });

      test('returns error for too short name', () {
        expect(Validators.validateName('A'), isNotNull);
      });

      test('returns null for valid name', () {
        expect(Validators.validateName('John'), isNull);
        expect(Validators.validateName('Sarah Johnson'), isNull);
      });
    });

    group('validateConfirmPassword', () {
      test('returns error for empty confirm', () {
        expect(Validators.validateConfirmPassword('', 'password'), isNotNull);
      });

      test('returns error for mismatch', () {
        expect(
            Validators.validateConfirmPassword('pass1', 'pass2'), isNotNull);
      });

      test('returns null for matching passwords', () {
        expect(Validators.validateConfirmPassword('password', 'password'),
            isNull);
      });
    });
  });
}
