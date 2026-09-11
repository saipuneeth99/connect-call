import 'package:get/get.dart';
import '../../../core/errors/error_handler.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../app/routes/app_routes.dart';

import '../../../data/repositories/user_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final UserRepository? _userRepository;

  AuthController(this._authRepository, [this._userRepository]);

  final Rx<AppUser?> currentUser = Rx<AppUser?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  void togglePasswordVisibility() =>
      obscurePassword.value = !obscurePassword.value;

  void toggleConfirmPasswordVisibility() =>
      obscureConfirmPassword.value = !obscureConfirmPassword.value;

  void clearError() => errorMessage.value = '';

  Future<void> _syncUser(AppUser? user) async {
    if (user == null) return;
    try {
      final repo = _userRepository ??
          (Get.isRegistered<UserRepository>()
              ? Get.find<UserRepository>()
              : null);
      if (repo != null) {
        await repo.updateUser(user);
      }
    } catch (_) {
      // Non-blocking sync
    }
  }

  Future<void> login({required String email, required String password}) async {
    errorMessage.value = '';
    isLoading.value = true;

    try {
      final user =
          await _authRepository.login(email: email, password: password);
      currentUser.value = user;
      await _syncUser(user);
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    errorMessage.value = '';
    isLoading.value = true;

    try {
      final user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      currentUser.value = user;
      await _syncUser(user);
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  final RxBool isGoogleLoading = false.obs;

  Future<void> signInWithGoogle() async {
    errorMessage.value = '';
    isGoogleLoading.value = true;

    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        currentUser.value = user;
        await _syncUser(user);
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    } finally {
      isGoogleLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      currentUser.value = null;
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    }
  }
}
