import 'package:get/get.dart';
import '../controllers/contacts_controller.dart';
import '../../../data/repositories/contact_repository.dart';
import '../../../data/repositories/auth_repository.dart';

class ContactsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ContactsController(
          Get.find<ContactRepository>(),
          Get.isRegistered<AuthRepository>()
              ? Get.find<AuthRepository>()
              : null,
        ));
  }
}
