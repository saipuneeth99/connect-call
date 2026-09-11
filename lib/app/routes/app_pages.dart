import 'package:get/get.dart';
import 'app_routes.dart';
import '../../modules/splash/bindings/splash_binding.dart';
import '../../modules/splash/views/splash_view.dart';
import '../../modules/auth/bindings/auth_binding.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/auth/views/register_view.dart';
import '../../modules/home/bindings/home_binding.dart';
import '../../modules/home/views/main_navigation_view.dart';
import '../../modules/contacts/views/contact_detail_view.dart';
import '../../modules/profile/views/edit_profile_view.dart';
import '../../modules/history/views/call_detail_view.dart';
import '../../modules/calling/bindings/calling_binding.dart';
import '../../modules/calling/views/incoming_call_view.dart';
import '../../modules/calling/views/audio_call_view.dart';
import '../../modules/calling/views/video_call_view.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainNavigationView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.contactDetail,
      page: () => const ContactDetailView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.callDetail,
      page: () => const CallDetailView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.outgoingCall,
      page: () => const AudioCallView(),
      binding: CallingBinding(),
      transition: Transition.downToUp,
      fullscreenDialog: true,
    ),
    GetPage(
      name: AppRoutes.incomingCall,
      page: () => const IncomingCallView(),
      binding: CallingBinding(),
      transition: Transition.downToUp,
      fullscreenDialog: true,
    ),
    GetPage(
      name: AppRoutes.audioCall,
      page: () => const AudioCallView(),
      binding: CallingBinding(),
      transition: Transition.downToUp,
      fullscreenDialog: true,
    ),
    GetPage(
      name: AppRoutes.videoCall,
      page: () => const VideoCallView(),
      binding: CallingBinding(),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    ),
  ];
}
