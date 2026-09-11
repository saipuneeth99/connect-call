import 'package:get/get.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../mock/mock_data.dart';

class ProfileController extends GetxController {
  final UserRepository _userRepository;

  ProfileController(this._userRepository);

  final Rx<AppUser> user = MockData.currentUser.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  Future<void> updateName(String name) async {
    isLoading.value = true;
    try {
      final updated = user.value.copyWith(name: name);
      final result = await _userRepository.updateUser(updated);
      user.value = result;
    } catch (e) {
      errorMessage.value = 'Failed to update profile';
    } finally {
      isLoading.value = false;
    }
  }
}
