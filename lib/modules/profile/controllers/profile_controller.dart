import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../../mock/mock_storage_service.dart';
import '../../home/controllers/home_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileController extends GetxController {
  final UserRepository _userRepository;
  final AuthRepository? _authRepository;
  final StorageService? _storageService;

  ProfileController(
    this._userRepository, [
    this._authRepository,
    this._storageService,
  ]);

  StorageService get _storage =>
      _storageService ??
      (Get.isRegistered<StorageService>()
          ? Get.find<StorageService>()
          : MockStorageService());

  final Rx<AppUser> user = Rx<AppUser>(
    AppUser(
      id: '',
      name: 'User',
      email: '',
      isOnline: true,
      lastSeen: DateTime.now(),
    ),
  );

  final RxBool isLoading = false.obs;
  final RxBool isUploadingAvatar = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeUser = Get.find<HomeController>().currentUser.value;
        if (homeUser.id.isNotEmpty && homeUser.id != 'user_current') {
          user.value = homeUser;
        }
      }

      final authRepo = _authRepository ??
          (Get.isRegistered<AuthRepository>()
              ? Get.find<AuthRepository>()
              : null);

      AppUser? activeUser;
      if (authRepo != null) {
        activeUser = await authRepo.getCurrentUser();
      }

      final activeUid = activeUser?.id.trim().isNotEmpty == true
          ? activeUser!.id
          : (fb.FirebaseAuth.instance.currentUser?.uid ?? 'user_current');

      final dbUser = await _userRepository.getUserById(activeUid);
      if (dbUser != null) {
        user.value = dbUser;
      } else if (activeUser != null) {
        user.value = activeUser;
      }
    } catch (_) {
      // Keep fallback
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateName(String name) async {
    if (name.trim().isEmpty) return;
    isLoading.value = true;
    try {
      final updated = user.value.copyWith(name: name.trim());
      user.value = updated;

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().updateCurrentUser(updated);
      }
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().currentUser.value = updated;
      }

      _userRepository.updateUser(updated).catchError((e) {
        debugPrint('ProfileController: updateUser error: $e');
        return updated;
      });

      // Sync display name with Firebase Auth if logged in
      try {
        await fb.FirebaseAuth.instance.currentUser
            ?.updateDisplayName(name.trim());
      } catch (e) {
        debugPrint('ProfileController: error syncing display name: $e');
      }

      Get.snackbar(
        'Profile Updated',
        'Your display name has been updated.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      errorMessage.value = 'Failed to update profile: $e';
      Get.snackbar(
        'Update Failed',
        'Could not update profile. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadAvatar(
      {ImageSource source = ImageSource.gallery}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) {
        debugPrint('ProfileController: user cancelled image pick');
        return;
      }

      debugPrint('ProfileController: picked ${picked.name}, reading bytes...');
      isUploadingAvatar.value = true;
      final bytes = await picked.readAsBytes();
      debugPrint('ProfileController: read ${bytes.length} bytes');

      String activeId = user.value.id.trim();
      if (activeId.isEmpty) {
        activeId =
            fb.FirebaseAuth.instance.currentUser?.uid ?? 'user_current';
      }

      debugPrint('ProfileController: uploading for activeId = $activeId using $_storage');
      final uploadedUrl =
          await _storage.uploadAvatar(activeId, bytes, picked.name);
      debugPrint('ProfileController: uploadedUrl = $uploadedUrl');

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        final updated = user.value.copyWith(
          id: activeId,
          avatarUrl: uploadedUrl,
        );
        user.value = updated;

        // Propagate to HomeController and AuthController immediately
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().updateCurrentUser(updated);
        }
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().currentUser.value = updated;
        }

        Get.snackbar(
          'Photo Updated',
          'Your profile photo has been updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );

        // Update database and Firebase Auth asynchronously
        _userRepository.updateUser(updated).catchError((e) {
          debugPrint('ProfileController: updateUser error: $e');
          return updated;
        });

        fb.FirebaseAuth.instance.currentUser
            ?.updatePhotoURL(uploadedUrl)
            .catchError((e) {
          debugPrint('ProfileController: Firebase photo update error: $e');
        });
      }
    } catch (e, s) {
      debugPrint('ProfileController: error during avatar upload: $e\n$s');
      errorMessage.value = 'Failed to upload photo';
      Get.snackbar(
        'Upload Failed',
        'Could not update profile photo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  Future<void> removeAvatar() async {
    isUploadingAvatar.value = true;
    try {
      String activeId = user.value.id.trim();
      if (activeId.isEmpty) {
        activeId =
            fb.FirebaseAuth.instance.currentUser?.uid ?? 'user_current';
      }

      await _storage.deleteAvatar(activeId);

      final updated = user.value.copyWith(
        id: activeId,
        avatarUrl: '',
      );
      user.value = updated;

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().updateCurrentUser(updated);
      }
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().currentUser.value = updated;
      }

      _userRepository.updateUser(updated).catchError((e) {
        debugPrint('ProfileController: updateUser error on remove: $e');
        return updated;
      });

      fb.FirebaseAuth.instance.currentUser
          ?.updatePhotoURL(null)
          .catchError((_) {});

      Get.snackbar(
        'Photo Removed',
        'Your profile photo has been removed.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('ProfileController: error removing avatar: $e');
      errorMessage.value = 'Failed to remove photo';
      Get.snackbar(
        'Remove Failed',
        'Could not remove profile photo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  void showPhotoOptionsSheet(BuildContext context) {
    final hasAvatar =
        user.value.avatarUrl != null && user.value.avatarUrl!.trim().isNotEmpty;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Profile Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: AppColors.primaryLight),
                ),
                title: const Text('Take photo',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Get.back();
                  pickAndUploadAvatar(source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primaryLight),
                ),
                title: const Text('Choose from gallery',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Get.back();
                  pickAndUploadAvatar(source: ImageSource.gallery);
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.red),
                  ),
                  title: const Text(
                    'Remove photo',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Get.back();
                    removeAvatar();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
