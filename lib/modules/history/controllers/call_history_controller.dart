import 'package:get/get.dart';
import '../../../core/errors/error_handler.dart';
import '../../../data/models/call.dart';
import '../../../data/repositories/call_repository.dart';
import '../../../mock/mock_data.dart';

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
      final calls =
          await _callRepository.getCallHistory(MockData.currentUserId);
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
