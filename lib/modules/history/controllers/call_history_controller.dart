import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/error_handler.dart';
import '../../../data/models/call.dart';
import '../../../data/repositories/call_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../home/controllers/home_controller.dart';

class CallHistoryController extends GetxController {
  final CallRepository _callRepository;

  CallHistoryController(this._callRepository);

  final RxList<Call> allCalls = <Call>[].obs;
  final RxList<Call> displayedCalls = <Call>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxBool showMissedOnly = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      String userId = '';
      try {
        if (Get.isRegistered<AuthRepository>()) {
          final authUser = await Get.find<AuthRepository>().getCurrentUser();
          if (authUser != null && authUser.id.isNotEmpty) {
            userId = authUser.id;
          }
        }
      } catch (_) {}

      if (userId.isEmpty && Get.isRegistered<HomeController>()) {
        final homeUser = Get.find<HomeController>().currentUser.value;
        if (homeUser.id.isNotEmpty) {
          userId = homeUser.id;
        }
      }

      if (userId.isEmpty || userId == 'user_current') {
        try {
          if (Supabase.instance.isInitialized) {
            final supaId = Supabase.instance.client.auth.currentUser?.id;
            if (supaId != null && supaId.isNotEmpty) {
              userId = supaId;
            }
          }
        } catch (_) {}
      }

      if (userId.isEmpty) {
        userId = 'user_current';
      }

      final calls = await _callRepository.getCallHistory(userId);
      allCalls.value = calls;
      _applyFilter();
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleFilter() {
    showMissedOnly.value = !showMissedOnly.value;
    _applyFilter();
  }

  void setFilter(bool missedOnly) {
    showMissedOnly.value = missedOnly;
    _applyFilter();
  }

  void _applyFilter() {
    if (showMissedOnly.value) {
      displayedCalls.value =
          allCalls.where((c) => c.isMissed).toList();
    } else {
      displayedCalls.value = List.from(allCalls);
    }
  }
}
