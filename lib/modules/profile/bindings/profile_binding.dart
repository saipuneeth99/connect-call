import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../data/repositories/user_repository.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProfileController(Get.find<UserRepository>()));
  }
}
