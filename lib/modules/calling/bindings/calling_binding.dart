import 'package:get/get.dart';
import '../controllers/call_controller.dart';
import '../../../data/repositories/call_repository.dart';
import '../../../data/repositories/user_repository.dart';

class CallingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CallController>()) {
      Get.put(
        CallController(
          Get.find<CallRepository>(),
          Get.find<UserRepository>(),
        ),
        permanent: true,
      );
    }
  }
}
