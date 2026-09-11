import 'package:get/get.dart';
import '../../../core/errors/error_handler.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/call.dart';
import '../../../data/repositories/call_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/call_signaling_service.dart';

class HomeController extends GetxController {
  final UserRepository _userRepository;
  final CallRepository _callRepository;
  final AuthRepository? _authRepository;

  HomeController(
    this._userRepository,
    this._callRepository, [
    this._authRepository,
  ]);

  final Rx<AppUser> currentUser = Rx<AppUser>(
    AppUser(
      id: '',
      name: 'Connecting...',
      email: '',
      isOnline: true,
      lastSeen: DateTime.now(),
    ),
  );

  final RxList<AppUser> favorites = <AppUser>[].obs;
  final RxList<Call> recentCalls = <Call>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void updateCurrentUser(AppUser user) {
    currentUser.value = user;
  }

  Future<void> loadData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final authRepo = _authRepository ??
          (Get.isRegistered<AuthRepository>()
              ? Get.find<AuthRepository>()
              : null);

      AppUser? activeUser;
      if (authRepo != null) {
        activeUser = await authRepo.getCurrentUser();
      }

      if (activeUser != null) {
        // Fetch latest details from Supabase (including any name/avatar updates)
        final dbUser = await _userRepository.getUserById(activeUser.id);
        if (dbUser != null) {
          currentUser.value = dbUser;
        } else {
          currentUser.value = activeUser;
          // Sync new user to Supabase
          try {
            await _userRepository.updateUser(activeUser);
          } catch (_) {}
        }
      } else {
        // Fallback to active demo user in Supabase
        final dbUser = await _userRepository.getUserById('user_current');
        if (dbUser != null) {
          currentUser.value = dbUser;
        } else {
          currentUser.value = AppUser(
            id: 'user_current',
            name: 'User',
            email: 'user@connectcall.app',
            isOnline: true,
          );
        }
      }

      final uid = currentUser.value.id;
      if (uid.isNotEmpty) {
        CallSignalingService.instance.init(uid);
      }

      final results = await Future.wait([
        _userRepository.getFavorites(uid),
        _callRepository.getCallHistory(uid),
      ]);

      final rawFavorites = results[0] as List<AppUser>;
      final activeUid = currentUser.value.id;
      final activeEmail = currentUser.value.email.toLowerCase();
      final activeName = currentUser.value.name.toLowerCase();

      favorites.value = rawFavorites.where((u) {
        if (u.id == activeUid || u.id == 'user_current') return false;
        if (activeEmail.isNotEmpty && u.email.toLowerCase() == activeEmail) {
          return false;
        }
        if (u.name.toLowerCase() == activeName) return false;
        return true;
      }).toList();

      final calls = results[1] as List<Call>;
      recentCalls.value = calls.take(6).toList();
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    } finally {
      isLoading.value = false;
    }
  }
}
