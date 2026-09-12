import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/call_status.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/services/call_signaling_service.dart';
import '../../calling/bindings/calling_binding.dart';
import '../../calling/controllers/call_controller.dart';

class SplashController extends GetxController {
  final AuthRepository _authRepository;

  SplashController(this._authRepository);

  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        CallSignalingService.instance.init(user.id);

        try {
          final activeCalls = await FlutterCallkitIncoming.activeCalls();
          if (activeCalls.isNotEmpty) {
            final call = activeCalls.first;
            final extra = call.extra ?? <String, dynamic>{};
            final callId = (extra['callId'] as String?) ?? call.id;
            final callerId = extra['callerId'] as String?;
            final callerName = (extra['callerName'] as String?) ??
                call.nameCaller ??
                'Incoming Call';
            final callTypeStr = (extra['callType'] as String?) ?? 'audio';
            final callType =
                callTypeStr == 'video' ? CallType.video : CallType.audio;

            if (call.isAccepted && callId.isNotEmpty) {
              CallingBinding().dependencies();
              final callCtrl = Get.find<CallController>();
              callCtrl.setupIncomingCall(
                caller: AppUser(
                  id: callerId ?? 'caller',
                  name: callerName,
                  email: '',
                  isOnline: true,
                ),
                type: callType,
                callId: callId,
              );
              await callCtrl.acceptCall();
              if (callType == CallType.video) {
                Get.offAllNamed(AppRoutes.videoCall);
              } else {
                Get.offAllNamed(AppRoutes.audioCall);
              }
              return;
            }
          }
        } catch (_) {}

        if (Get.currentRoute == AppRoutes.incomingCall ||
            Get.currentRoute == AppRoutes.audioCall ||
            Get.currentRoute == AppRoutes.videoCall) {
          return;
        }

        Get.offAllNamed(AppRoutes.home);
      } else {
        if (Get.currentRoute == AppRoutes.incomingCall ||
            Get.currentRoute == AppRoutes.audioCall ||
            Get.currentRoute == AppRoutes.videoCall) {
          return;
        }
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (_) {
      if (Get.currentRoute == AppRoutes.incomingCall ||
          Get.currentRoute == AppRoutes.audioCall ||
          Get.currentRoute == AppRoutes.videoCall) {
        return;
      }
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
