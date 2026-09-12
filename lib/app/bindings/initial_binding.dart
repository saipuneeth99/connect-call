import 'package:get/get.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/call_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/calling_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/connectivity_service.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../mock/mock_auth_service.dart';
import '../../mock/mock_user_service.dart';
import '../../mock/mock_calling_service.dart';
import '../../mock/mock_storage_service.dart';
import '../../mock/mock_permission_service.dart';
import '../../mock/mock_connectivity_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/supabase_user_service.dart';
import '../../data/services/supabase_storage_service.dart';
import '../../data/services/livekit_calling_service.dart';

import '../../modules/calling/bindings/calling_binding.dart';

import '../../data/services/contact_service.dart';
import '../../data/services/supabase_contact_service.dart';
import '../../mock/mock_contact_service.dart';
import '../../data/repositories/contact_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    if (Firebase.apps.isNotEmpty) {
      Get.put<AuthService>(FirebaseAuthService(), permanent: true);
    } else {
      Get.put<AuthService>(MockAuthService(), permanent: true);
    }

    bool hasSupabase = false;
    try {
      hasSupabase = Supabase.instance.isInitialized;
    } catch (_) {
      hasSupabase = false;
    }

    if (hasSupabase) {
      Get.put<UserService>(SupabaseUserService(), permanent: true);
      Get.put<StorageService>(SupabaseStorageService(), permanent: true);
      Get.put<ContactService>(SupabaseContactService(), permanent: true);
    } else {
      Get.put<UserService>(MockUserService(), permanent: true);
      Get.put<StorageService>(MockStorageService(), permanent: true);
      Get.put<ContactService>(MockContactService(), permanent: true);
    }

    if (hasSupabase || Firebase.apps.isNotEmpty) {
      Get.put<CallingService>(LiveKitCallingService(), permanent: true);
    } else {
      Get.put<CallingService>(MockCallingService(), permanent: true);
    }
    Get.put<PermissionService>(MockPermissionService(), permanent: true);
    Get.put<ConnectivityService>(MockConnectivityService(), permanent: true);

    // Repositories
    Get.put(AuthRepository(Get.find<AuthService>()), permanent: true);
    Get.put(UserRepository(Get.find<UserService>()), permanent: true);
    Get.put(ContactRepository(Get.find<ContactService>()), permanent: true);
    Get.put(CallRepository(Get.find<CallingService>()), permanent: true);
    Get.lazyPut(
      () => AuthController(
        Get.find<AuthRepository>(),
        Get.find<UserRepository>(),
      ),
      fenix: true,
    );

    // Calling Controller (registered permanently for real-time signaling)
    CallingBinding().dependencies();
  }
}
