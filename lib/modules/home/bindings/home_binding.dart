import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/main_navigation_controller.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/call_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../../modules/contacts/controllers/contacts_controller.dart';
import '../../../modules/history/controllers/call_history_controller.dart';
import '../../../modules/profile/controllers/profile_controller.dart';

import '../../../data/repositories/contact_repository.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(MainNavigationController());
    Get.lazyPut(() => HomeController(
          Get.find<UserRepository>(),
          Get.find<CallRepository>(),
          Get.isRegistered<AuthRepository>()
              ? Get.find<AuthRepository>()
              : null,
          Get.isRegistered<ContactRepository>()
              ? Get.find<ContactRepository>()
              : null,
        ));
    Get.lazyPut(() => ContactsController(
          Get.find<ContactRepository>(),
          Get.isRegistered<AuthRepository>()
              ? Get.find<AuthRepository>()
              : null,
        ));
    Get.lazyPut(() => CallHistoryController(Get.find<CallRepository>()));
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
