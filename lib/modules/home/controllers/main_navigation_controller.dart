import 'package:get/get.dart';
import '../../contacts/controllers/contacts_controller.dart';
import '../../history/controllers/call_history_controller.dart';
import 'home_controller.dart';

class MainNavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;

    if (index == 0) {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadData();
      }
    } else if (index == 1) {
      if (Get.isRegistered<ContactsController>()) {
        Get.find<ContactsController>().loadData();
      }
    } else if (index == 2) {
      if (Get.isRegistered<CallHistoryController>()) {
        Get.find<CallHistoryController>().loadHistory();
      }
    }
  }
}
