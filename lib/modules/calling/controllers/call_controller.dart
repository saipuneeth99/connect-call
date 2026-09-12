import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_handler.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/call_status.dart';
import '../../../data/repositories/call_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/call_signaling_service.dart';
import '../../../modules/history/controllers/call_history_controller.dart';
import '../../../modules/home/controllers/home_controller.dart';
import '../../../app/routes/app_routes.dart';

class CallController extends GetxController {
  final CallRepository _callRepository;
  final UserRepository _userRepository;

  CallController(this._callRepository, this._userRepository);

  final Rx<CallStatus> callStatus = CallStatus.idle.obs;
  final Rx<AppUser?> remoteUser = Rx<AppUser?>(null);
  final Rx<CallType> callType = CallType.audio.obs;
  final Rx<CallDirection> callDirection = CallDirection.outgoing.obs;
  final RxBool isMuted = false.obs;
  final RxBool isSpeakerOn = false.obs;
  final RxBool isCameraOn = true.obs;
  final RxBool isFrontCamera = true.obs;
  final RxBool showControls = true.obs;
  final RxString callDuration = '00:00'.obs;
  final RxString errorMessage = ''.obs;
  final RxString dialedDigits = ''.obs;

  String? _currentCallId;
  String? get currentCallId => _currentCallId;
  Timer? _durationTimer;
  DateTime? _connectedAt;
  StreamSubscription<CallStatus>? _statusSubscription;
  StreamSubscription<Map<String, dynamic>>? _signalingReplySub;
  StreamSubscription<Map<String, dynamic>>? _signalingEndSub;
  bool _acceptInProgress = false;
  bool _terminateInProgress = false;

  Future<void> startOutgoingCall({
    required String receiverId,
    required CallType type,
    AppUser? fallbackUser,
  }) async {
    // Prevent duplicate initiation if already calling this user
    if (_currentCallId != null &&
        remoteUser.value?.id == receiverId &&
        (callStatus.value == CallStatus.calling ||
            callStatus.value == CallStatus.ringing ||
            callStatus.value == CallStatus.connected)) {
      return;
    }

    _cleanupSession();

    try {
      AppUser? user = fallbackUser;
      user ??= await _userRepository.getUserById(receiverId);
      user ??= AppUser(
        id: receiverId,
        name: 'Contact',
        email: '',
        isOnline: true,
      );

      remoteUser.value = user;
      callType.value = type;
      callDirection.value = CallDirection.outgoing;
      callStatus.value = CallStatus.calling;
      isCameraOn.value = type == CallType.video;
      isSpeakerOn.value = type == CallType.video;
      isMuted.value = false;
      dialedDigits.value = '';

      _currentCallId = 'call_${DateTime.now().millisecondsSinceEpoch}';

      AppUser currentCaller = AppUser(
        id: 'user_current',
        name: 'Caller',
        email: '',
        isOnline: true,
      );
      if (Get.isRegistered<AuthRepository>()) {
        final currentUser = await Get.find<AuthRepository>().getCurrentUser();
        if (currentUser != null && currentUser.id.isNotEmpty) {
          currentCaller = currentUser;
        }
      }
      if (currentCaller.id == 'user_current' &&
          Supabase.instance.isInitialized) {
        final supaUser = Supabase.instance.client.auth.currentUser;
        if (supaUser != null) {
          currentCaller = AppUser(
            id: supaUser.id,
            name:
                (supaUser.userMetadata?['full_name'] as String?) ??
                supaUser.email?.split('@').first ??
                'Caller',
            email: supaUser.email ?? '',
            avatarUrl: supaUser.userMetadata?['avatar_url'] as String?,
            isOnline: true,
          );
        }
      }

      // Attach status listener BEFORE starting call so events are never lost
      _listenToCallStatus();

      // Listen for recipient response over real-time signaling
      _listenToSignalingEvents();

      // Send real-time call invitation to the recipient device
      CallSignalingService.instance.sendInvite(
        receiverId: receiverId,
        callId: _currentCallId!,
        caller: currentCaller,
        type: type,
      );

      await _callRepository.startCall(
        callId: _currentCallId!,
        callerId: currentCaller.id,
        receiverId: receiverId,
        type: type,
      );
    } catch (e) {
      debugPrint('CallController startOutgoingCall error: $e');
      errorMessage.value = ErrorHandler.getUserMessage(e);
      callStatus.value = CallStatus.failed;
    }
  }

  void setupIncomingCall({
    required AppUser caller,
    required CallType type,
    required String callId,
  }) {
    _cleanupSession();

    remoteUser.value = caller;
    callType.value = type;
    callDirection.value = CallDirection.incoming;
    callStatus.value = CallStatus.ringing;
    _currentCallId = callId;
    isCameraOn.value = type == CallType.video;
    isSpeakerOn.value = type == CallType.video;

    _listenToCallStatus();
    _listenToSignalingEvents();
  }

  Future<void> acceptCall() async {
    if (_acceptInProgress || callStatus.value == CallStatus.connected) return;
    _acceptInProgress = true;
    CallSignalingService.dismissVoipNotification();
    if (_currentCallId == null) {
      _acceptInProgress = false;
      return;
    }

    try {
      final callerId = remoteUser.value?.id;
      if (callerId != null) {
        await CallSignalingService.instance.sendReply(
          callerId: callerId,
          callId: _currentCallId!,
          status: 'accepted',
        );
      }

      // Navigate to call view
      if (callType.value == CallType.video) {
        Get.offNamed(AppRoutes.videoCall);
      } else {
        Get.offNamed(AppRoutes.audioCall);
      }

      if (callType.value == CallType.audio && !isSpeakerOn.value) {
        CallSignalingService.enableProximitySensor();
      }

      await _callRepository.acceptCall(_currentCallId!, callType.value);
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    } finally {
      _acceptInProgress = false;
    }
  }

  Future<void> rejectCall() async {
    if (_terminateInProgress) return;
    _terminateInProgress = true;
    CallSignalingService.dismissVoipNotification();
    CallSignalingService.disableProximitySensor();
    final callId = _currentCallId;
    final callerId = remoteUser.value?.id;
    callStatus.value = CallStatus.rejected;
    _stopDurationTimer();

    if (callerId != null && callId != null) {
      CallSignalingService.instance.sendReply(
        callerId: callerId,
        callId: callId,
        status: 'rejected',
      );
    }

    if (callId != null) {
      try {
        await _callRepository.rejectCall(callId);
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _cleanupSession();
    _popCallScreen();
    _terminateInProgress = false;
  }

  Future<void> endCall() async {
    if (_terminateInProgress) return;
    _terminateInProgress = true;
    CallSignalingService.dismissVoipNotification();
    CallSignalingService.endAllCallkitCalls();
    CallSignalingService.disableProximitySensor();
    final callId = _currentCallId;
    final otherId = remoteUser.value?.id;
    callStatus.value = CallStatus.ended;
    _stopDurationTimer();

    if (otherId != null && callId != null) {
      CallSignalingService.instance.sendEnd(
        otherUserId: otherId,
        callId: callId,
      );
    }

    if (callId != null) {
      try {
        await _callRepository.endCall(callId);
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _cleanupSession();
    _popCallScreen();
    _terminateInProgress = false;
  }

  Future<void> toggleMute() async {
    if (_currentCallId == null) return;
    try {
      await _callRepository.toggleMute(_currentCallId!);
      isMuted.value = !isMuted.value;
    } catch (e) {
      debugPrint('toggleMute error: $e');
    }
  }

  Future<void> toggleSpeaker() async {
    if (_currentCallId == null) return;
    try {
      await _callRepository.toggleSpeaker(_currentCallId!);
      isSpeakerOn.value = !isSpeakerOn.value;
      if (callType.value == CallType.audio &&
          callStatus.value == CallStatus.connected) {
        if (isSpeakerOn.value) {
          CallSignalingService.disableProximitySensor();
        } else {
          CallSignalingService.enableProximitySensor();
        }
      }
    } catch (e) {
      debugPrint('toggleSpeaker error: $e');
    }
  }

  Future<void> toggleCamera() async {
    if (_currentCallId == null) return;
    try {
      await _callRepository.toggleCamera(_currentCallId!);
      isCameraOn.value = !isCameraOn.value;
    } catch (e) {
      debugPrint('toggleCamera error: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_currentCallId == null) return;
    try {
      await _callRepository.switchCamera(_currentCallId!);
      isFrontCamera.value = !isFrontCamera.value;
    } catch (e) {
      debugPrint('switchCamera error: $e');
    }
  }

  void toggleControlsVisibility() {
    showControls.value = !showControls.value;
  }

  void dialDigit(String digit) {
    dialedDigits.value = dialedDigits.value + digit;
  }

  void clearDialedDigits() {
    dialedDigits.value = '';
  }

  Future<void> switchToVideoCall() async {
    if (callType.value == CallType.video) return;
    callType.value = CallType.video;
    isCameraOn.value = true;
    CallSignalingService.disableProximitySensor();
    if (_currentCallId != null) {
      try {
        await _callRepository.toggleCamera(_currentCallId!);
      } catch (_) {}
    }
    if (Get.currentRoute != AppRoutes.videoCall) {
      Get.toNamed(AppRoutes.videoCall);
    }
  }

  Future<void> switchToAudioCall() async {
    if (callType.value == CallType.audio) return;
    callType.value = CallType.audio;
    isCameraOn.value = false;
    if (!isSpeakerOn.value && callStatus.value == CallStatus.connected) {
      CallSignalingService.enableProximitySensor();
    }
    if (_currentCallId != null) {
      try {
        await _callRepository.toggleCamera(_currentCallId!);
      } catch (_) {}
    }
    if (Get.currentRoute == AppRoutes.videoCall) {
      Get.back();
    }
  }

  void _listenToCallStatus() {
    if (_currentCallId == null) return;

    _statusSubscription?.cancel();
    _statusSubscription = _callRepository
        .callStatusStream(_currentCallId!)
        .listen((status) {
          callStatus.value = status;

          if (status == CallStatus.connected) {
            if (_currentCallId != null) {
              CallSignalingService.markCallConnected(_currentCallId!);
            }
            _startDurationTimer();
            if (callType.value == CallType.audio && !isSpeakerOn.value) {
              CallSignalingService.enableProximitySensor();
            }
          }

          if (status.isTerminal) {
            _stopDurationTimer();
            CallSignalingService.endAllCallkitCalls();
            CallSignalingService.disableProximitySensor();
            Future.delayed(const Duration(milliseconds: 600), () {
              _cleanupSession();
              _popCallScreen();
            });
          }
        });
  }

  void _startDurationTimer() {
    if (_durationTimer != null) return;
    _connectedAt = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt != null) {
        final elapsed = DateTime.now().difference(_connectedAt!);
        final minutes = elapsed.inMinutes
            .remainder(60)
            .toString()
            .padLeft(2, '0');
        final seconds = elapsed.inSeconds
            .remainder(60)
            .toString()
            .padLeft(2, '0');
        final hours = elapsed.inHours;
        if (hours > 0) {
          callDuration.value =
              '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
        } else {
          callDuration.value = '$minutes:$seconds';
        }
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _listenToSignalingEvents() {
    _signalingReplySub?.cancel();
    _signalingReplySub = CallSignalingService.instance.onCallReply.listen((
      payload,
    ) {
      final callId = payload['callId'] as String?;
      final status = payload['status'] as String?;
      if (callId == _currentCallId) {
        if (status == 'accepted') {
          // The remote accepted the call, but media is not connected yet.
          // LiveKit will move both sides to connected after a participant
          // actually joins the room.
          callStatus.value = CallStatus.connecting;
        } else if (status == 'rejected') {
          callStatus.value = CallStatus.rejected;
          _stopDurationTimer();
          CallSignalingService.disableProximitySensor();
          Future.delayed(const Duration(milliseconds: 600), () {
            _cleanupSession();
            _popCallScreen();
          });
        } else if (status == 'busy') {
          errorMessage.value = 'User is busy on another call';
          callStatus.value = CallStatus.failed;
          CallSignalingService.disableProximitySensor();
          Future.delayed(const Duration(milliseconds: 1500), () {
            _cleanupSession();
            _popCallScreen();
          });
        }
      }
    });

    _signalingEndSub?.cancel();
    _signalingEndSub = CallSignalingService.instance.onCallEnded.listen((
      payload,
    ) async {
      final callId = payload['callId'] as String?;
      if (callId == _currentCallId) {
        callStatus.value = CallStatus.ended;
        _stopDurationTimer();
        CallSignalingService.disableProximitySensor();
        if (callId != null) {
          try {
            await _callRepository.endCall(callId);
          } catch (_) {}
        }
        await Future.delayed(const Duration(milliseconds: 600));
        _cleanupSession();
        _popCallScreen();
      }
    });
  }

  void _cleanupSession() {
    CallSignalingService.dismissVoipNotification();
    CallSignalingService.disableProximitySensor();
    _stopDurationTimer();
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _signalingReplySub?.cancel();
    _signalingReplySub = null;
    _signalingEndSub?.cancel();
    _signalingEndSub = null;
    _currentCallId = null;
    _connectedAt = null;
    callDuration.value = '00:00';
    isMuted.value = false;
    isSpeakerOn.value = false;
    isCameraOn.value = true;
    isFrontCamera.value = true;
    showControls.value = true;
    callStatus.value = CallStatus.idle;
    errorMessage.value = '';
    dialedDigits.value = '';

    // Auto-refresh call history and home recents on both devices
    try {
      if (Get.isRegistered<CallHistoryController>()) {
        Get.find<CallHistoryController>().loadHistory();
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadData();
      }
    } catch (_) {}
  }

  void _popCallScreen() {
    if (Get.currentRoute == AppRoutes.videoCall) {
      Get.back();
    }
    if (Get.currentRoute == AppRoutes.audioCall ||
        Get.currentRoute == AppRoutes.outgoingCall ||
        Get.currentRoute == AppRoutes.incomingCall) {
      Get.back();
    }
  }

  @override
  void onClose() {
    if (_currentCallId != null && callStatus.value != CallStatus.ended) {
      endCall();
    } else {
      _cleanupSession();
    }
    super.onClose();
  }
}
