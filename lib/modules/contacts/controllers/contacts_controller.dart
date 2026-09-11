import 'package:get/get.dart';
import '../../../core/errors/error_handler.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/auth_repository.dart';

class ContactsController extends GetxController {
  final UserRepository _userRepository;

  ContactsController(this._userRepository);

  final RxList<AppUser> users = <AppUser>[].obs;
  final RxList<AppUser> filteredUsers = <AppUser>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    debounce(searchQuery, _performSearch,
        time: const Duration(milliseconds: 300));
  }

  Future<void> loadUsers() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      String? currentUid;
      String? currentName;
      String? currentEmail;
      if (Get.isRegistered<AuthRepository>()) {
        final current = await Get.find<AuthRepository>().getCurrentUser();
        currentUid = current?.id;
        currentName = current?.name.toLowerCase();
        currentEmail = current?.email.toLowerCase();
      }

      final result = await _userRepository.getUsers();
      final sanitized = result.where((u) {
        if (currentUid != null && u.id == currentUid) return false;
        if (u.id == 'user_current') return false;
        if (currentEmail != null &&
            currentEmail.isNotEmpty &&
            u.email.toLowerCase() == currentEmail) {
          return false;
        }
        if (currentName != null &&
            currentName.isNotEmpty &&
            u.name.toLowerCase() == currentName) {
          return false;
        }
        return true;
      }).toList();

      users.value = sanitized;
      filteredUsers.value = sanitized;
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      filteredUsers.value = users;
      return;
    }

    try {
      final results = await _userRepository.searchUsers(query);
      String? currentUid;
      if (Get.isRegistered<AuthRepository>()) {
        final current = await Get.find<AuthRepository>().getCurrentUser();
        currentUid = current?.id;
      }
      final sanitized = currentUid != null && currentUid.isNotEmpty
          ? results.where((u) => u.id != currentUid).toList()
          : results;
      filteredUsers.value = sanitized;
    } catch (e) {
      final lowerQuery = query.toLowerCase();
      filteredUsers.value = users
          .where((user) =>
              user.name.toLowerCase().contains(lowerQuery) ||
              user.email.toLowerCase().contains(lowerQuery))
          .toList();
    }
  }
}
