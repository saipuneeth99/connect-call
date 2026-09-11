import 'dart:async';
import 'package:get/get.dart';
import '../../../core/errors/error_handler.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/call_status.dart';
import '../../../data/repositories/call_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../mock/mock_data.dart';
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

  String? _currentCallId;
  Timer? _durationTimer;
  DateTime? _connectedAt;
  StreamSubscription<CallStatus>? _statusSubscription;


  Future<void> startOutgoingCall({
    required String receiverId,
    required CallType type,
  }) async {
    try {
      final user = await _userRepository.getUserById(receiverId);
      if (user == null) {
        errorMessage.value = 'User not found';
        return;
      }

      remoteUser.value = user;
      callType.value = type;
      callDirection.value = CallDirection.outgoing;
      isCameraOn.value = type == CallType.video;

      _currentCallId =
          'call_${DateTime.now().millisecondsSinceEpoch}';

      String callerId = MockData.currentUserId;
      if (Get.isRegistered<AuthRepository>()) {
        final currentUser = await Get.find<AuthRepository>().getCurrentUser();
        if (currentUser != null) {
          callerId = currentUser.id;
        }
      }

      await _callRepository.startCall(
        callId: _currentCallId!,
        callerId: callerId,
        receiverId: receiverId,
        type: type,
      );

      _listenToCallStatus();
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    }
  }

  void setupIncomingCall({
    required AppUser caller,
    required CallType type,
    required String callId,
  }) {
    remoteUser.value = caller;
    callType.value = type;
    callDirection.value = CallDirection.incoming;
    callStatus.value = CallStatus.ringing;
    _currentCallId = callId;
    isCameraOn.value = type == CallType.video;

    _listenToCallStatus();
  }

  Future<void> acceptCall() async {
    if (_currentCallId == null) return;

    try {
      await _callRepository.acceptCall(_currentCallId!);
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    }
  }

  Future<void> rejectCall() async {
    if (_currentCallId == null) return;

    try {
      await _callRepository.rejectCall(_currentCallId!);
      _cleanup();
      Get.back();
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    }
  }

  Future<void> endCall() async {
    if (_currentCallId == null) return;

    try {
      await _callRepository.endCall(_currentCallId!);
    } catch (e) {
      errorMessage.value = ErrorHandler.getUserMessage(e);
    }
  }

  Future<void> toggleMute() async {
    if (_currentCallId == null) return;
    await _callRepository.toggleMute(_currentCallId!);
    isMuted.value = !isMuted.value;
  }

  Future<void> toggleSpeaker() async {
    if (_currentCallId == null) return;
    await _callRepository.toggleSpeaker(_currentCallId!);
    isSpeakerOn.value = !isSpeakerOn.value;
  }

  Future<void> toggleCamera() async {
    if (_currentCallId == null) return;
    await _callRepository.toggleCamera(_currentCallId!);
    isCameraOn.value = !isCameraOn.value;
  }

  Future<void> switchCamera() async {
    if (_currentCallId == null) return;
    await _callRepository.switchCamera(_currentCallId!);
    isFrontCamera.value = !isFrontCamera.value;
  }

  void toggleControlsVisibility() {
    showControls.value = !showControls.value;
  }

  void _listenToCallStatus() {
    if (_currentCallId == null) return;

    _statusSubscription =
        _callRepository.callStatusStream(_currentCallId!).listen((status) {
      callStatus.value = status;

      if (status == CallStatus.connected) {
        _startDurationTimer();
        // Navigate to call screen if on outgoing/incoming
        if (callType.value == CallType.video) {
          Get.offNamed(AppRoutes.videoCall);
        } else {
          Get.offNamed(AppRoutes.audioCall);
        }
      }

      if (status.isTerminal) {
        _stopDurationTimer();
        Future.delayed(const Duration(seconds: 2), () {
          _cleanup();
          if (Get.currentRoute == AppRoutes.audioCall ||
              Get.currentRoute == AppRoutes.videoCall ||
              Get.currentRoute == AppRoutes.outgoingCall ||
              Get.currentRoute == AppRoutes.incomingCall) {
            Get.until((route) => route.isFirst);
          }
        });
      }
    });
  }

  void _startDurationTimer() {
    _connectedAt = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt != null) {
        final elapsed = DateTime.now().difference(_connectedAt!);
        final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
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

  void _cleanup() {
    _stopDurationTimer();
    _statusSubscription?.cancel();
    _statusSubscription = null;
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
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }
}
