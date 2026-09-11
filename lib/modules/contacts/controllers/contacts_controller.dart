import 'package:get/get.dart';
import '../../../core/errors/error_handler.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';

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
      final result = await _userRepository.getUsers();
      users.value = result;
      filteredUsers.value = result;
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
      filteredUsers.value = results;
    } catch (e) {
      // Silently fall back to local filter
      final lowerQuery = query.toLowerCase();
      filteredUsers.value = users
          .where((user) =>
              user.name.toLowerCase().contains(lowerQuery) ||
              user.email.toLowerCase().contains(lowerQuery))
          .toList();
    }
  }
}
