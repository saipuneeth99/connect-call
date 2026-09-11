import '../models/app_user.dart';

abstract class AuthService {
  Future<AppUser?> login({required String email, required String password});
  Future<AppUser?> register({
    required String name,
    required String email,
    required String password,
  });
  Future<AppUser?> signInWithGoogle();
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
  Stream<AppUser?> get authStateChanges;
}
