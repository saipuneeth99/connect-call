import 'package:get/get.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../app/routes/app_routes.dart';

import '../../../data/services/call_signaling_service.dart';

class SplashController extends GetxController {
  final AuthRepository _authRepository;

  SplashController(this._authRepository);

  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        CallSignalingService.instance.init(user.id);
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (_) {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
