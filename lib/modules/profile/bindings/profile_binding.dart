import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/storage_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProfileController(
          Get.find<UserRepository>(),
          Get.isRegistered<AuthRepository>()
              ? Get.find<AuthRepository>()
              : null,
          Get.isRegistered<StorageService>()
              ? Get.find<StorageService>()
              : null,
        ));
  }
}
