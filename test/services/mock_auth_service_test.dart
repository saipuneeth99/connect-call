import 'package:flutter_test/flutter_test.dart';
import 'package:connect_call/mock/mock_auth_service.dart';
import 'package:connect_call/core/errors/app_exception.dart';

void main() {
  late MockAuthService authService;

  setUp(() {
    authService = MockAuthService();
  });

  group('MockAuthService', () {
    test('login with demo credentials returns user', () async {
      final user = await authService.login(
        email: 'demo@connectcall.app',
        password: 'password123',
      );

      expect(user, isNotNull);
      expect(user!.email, 'demo@connectcall.app');
    });

    test('login with wrong credentials throws AuthException', () async {
      expect(
        () => authService.login(email: 'wrong@test.com', password: 'wrong'),
        throwsA(isA<AuthException>()),
      );
    });

    test('register creates new user', () async {
      final user = await authService.register(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      );

      expect(user, isNotNull);
      expect(user!.name, 'Test User');
      expect(user.email, 'test@example.com');
    });

    test('register with existing email throws AuthException', () async {
      expect(
        () => authService.register(
          name: 'Test',
          email: 'demo@connectcall.app',
          password: 'password123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('getCurrentUser returns null before login', () async {
      final user = await authService.getCurrentUser();
      expect(user, isNull);
    });

    test('getCurrentUser returns user after login', () async {
      await authService.login(
        email: 'demo@connectcall.app',
        password: 'password123',
      );

      final user = await authService.getCurrentUser();
      expect(user, isNotNull);
    });

    test('logout clears current user', () async {
      await authService.login(
        email: 'demo@connectcall.app',
        password: 'password123',
      );
      await authService.logout();

      final user = await authService.getCurrentUser();
      expect(user, isNull);
    });
  });
}
