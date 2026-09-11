import 'package:get/get.dart';
import '../controllers/call_history_controller.dart';
import '../../../data/repositories/call_repository.dart';

class HistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CallHistoryController(Get.find<CallRepository>()));
  }
}
