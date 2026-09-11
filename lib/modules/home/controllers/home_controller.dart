import 'package:get/get.dart';
import '../../../core/errors/error_handler.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/call.dart';
import '../../../data/repositories/call_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../mock/mock_data.dart';

class HomeController extends GetxController {
  final UserRepository _userRepository;
  final CallRepository _callRepository;

  HomeController(this._userRepository, this._callRepository);

  final Rx<AppUser> currentUser = MockData.currentUser.obs;
  final RxList<AppUser> favorites = <AppUser>[].obs;
  final RxList<Call> recentCalls = <Call>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final results = await Future.wait([
        _userRepository.getFavorites(MockData.currentUserId),
        _callRepository.getCallHistory(MockData.currentUserId),
      ]);

      favorites.value = results[0] as List<AppUser>;
      final calls = results[1] as List<Call>;
      recentCalls.value = calls.take(4).toList();
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    } finally {
      isLoading.value = false;
    }
  }
}
