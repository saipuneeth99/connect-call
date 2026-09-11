import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/call_repository.dart';
import '../../../modules/contacts/controllers/contacts_controller.dart';
import '../../../modules/history/controllers/call_history_controller.dart';
import '../../../modules/profile/controllers/profile_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController(
          Get.find<UserRepository>(),
          Get.find<CallRepository>(),
        ));
    Get.lazyPut(() => ContactsController(Get.find<UserRepository>()));
    Get.lazyPut(() => CallHistoryController(Get.find<CallRepository>()));
    Get.lazyPut(() => ProfileController(Get.find<UserRepository>()));
  }
}
