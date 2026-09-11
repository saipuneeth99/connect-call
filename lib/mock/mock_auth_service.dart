import 'dart:async';
import '../core/errors/app_exception.dart';
import '../data/models/app_user.dart';
import '../data/services/auth_service.dart';
import 'mock_data.dart';

class MockAuthService implements AuthService {
  AppUser? _currentUser;
  final _authController = StreamController<AppUser?>.broadcast();
  final List<AppUser> _registeredUsers = [];

  @override
  Future<AppUser?> login(
      {required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (email == 'demo@connectcall.app' && password == 'password123') {
      _currentUser = MockData.currentUser;
      _authController.add(_currentUser);
      return _currentUser;
    }

    final registered = _registeredUsers
        .where((u) => u.email == email)
        .firstOrNull;
    if (registered != null) {
      _currentUser = registered;
      _authController.add(_currentUser);
      return _currentUser;
    }

    throw const AuthException('Invalid email or password.');
  }

  @override
  Future<AppUser?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (email == 'demo@connectcall.app' ||
        _registeredUsers.any((u) => u.email == email)) {
      throw const AuthException('An account with this email already exists.');
    }

    final user = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    _registeredUsers.add(user);
    _currentUser = user;
    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = MockData.currentUser;
    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }

  @override
  Stream<AppUser?> get authStateChanges => _authController.stream;
}
