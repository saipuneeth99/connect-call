import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  Future<AppUser?> login(
          {required String email, required String password}) =>
      _authService.login(email: email, password: password);

  Future<AppUser?> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _authService.register(name: name, email: email, password: password);

  Future<AppUser?> signInWithGoogle() => _authService.signInWithGoogle();

  Future<void> logout() => _authService.logout();

  Future<AppUser?> getCurrentUser() => _authService.getCurrentUser();

  Stream<AppUser?> get authStateChanges => _authService.authStateChanges;
}
