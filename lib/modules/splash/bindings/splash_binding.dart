import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../../../data/repositories/auth_repository.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController(Get.find<AuthRepository>()));
  }
}
