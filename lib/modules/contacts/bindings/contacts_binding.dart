import 'package:get/get.dart';
import '../controllers/contacts_controller.dart';
import '../../../data/repositories/user_repository.dart';

class ContactsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ContactsController(Get.find<UserRepository>()));
  }
}
