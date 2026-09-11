import 'dart:async';
import '../core/constants/app_constants.dart';
import '../data/models/call.dart';
import '../data/models/call_participant.dart';
import '../data/models/call_status.dart';
import '../data/services/calling_service.dart';
import 'mock_data.dart';

class MockCallingService implements CallingService {
  final Map<String, StreamController<CallStatus>> _statusControllers = {};
  final Map<String, Call> _activeCalls = {};
  final Map<String, bool> _muteState = {};
  final Map<String, bool> _speakerState = {};
  final Map<String, bool> _cameraState = {};
  final Map<String, bool> _frontCameraState = {};
  Timer? _simulationTimer;

  bool isMuted(String callId) => _muteState[callId] ?? false;
  bool isSpeakerOn(String callId) => _speakerState[callId] ?? false;
  bool isCameraOn(String callId) => _cameraState[callId] ?? true;
  bool isFrontCamera(String callId) => _frontCameraState[callId] ?? true;

  @override
  Future<void> startCall({
    required String callId,
    required String callerId,
    required String receiverId,
    required CallType type,
  }) async {
    final controller = StreamController<CallStatus>.broadcast();
    _statusControllers[callId] = controller;
    _muteState[callId] = false;
    _speakerState[callId] = false;
    _cameraState[callId] = type == CallType.video;
    _frontCameraState[callId] = true;

    final callerUser = MockData.users
        .where((u) => u.id == callerId)
        .firstOrNull;
    final receiverUser = MockData.users
        .where((u) => u.id == receiverId)
        .firstOrNull;

    _activeCalls[callId] = Call(
      id: callId,
      caller: CallParticipant(
        id: callerId,
        name: callerUser?.name ?? MockData.currentUser.name,
        avatarUrl: callerUser?.avatarUrl,
      ),
      receiver: CallParticipant(
        id: receiverId,
        name: receiverUser?.name ?? 'Unknown',
        avatarUrl: receiverUser?.avatarUrl,
      ),
      type: type,
      status: CallStatus.calling,
      direction: CallDirection.outgoing,
      startedAt: DateTime.now(),
    );

    controller.add(CallStatus.calling);

    _simulateOutgoingCall(callId, controller);
  }

  void _simulateOutgoingCall(
      String callId, StreamController<CallStatus> controller) {
    Future.delayed(
        const Duration(milliseconds: AppConstants.callRingingDurationMs), () {
      if (controller.isClosed) return;
      controller.add(CallStatus.ringing);
      _updateCallStatus(callId, CallStatus.ringing);

      Future.delayed(
          const Duration(milliseconds: AppConstants.callRingingDurationMs), () {
        if (controller.isClosed) return;
        controller.add(CallStatus.connecting);
        _updateCallStatus(callId, CallStatus.connecting);

        Future.delayed(
            const Duration(
                milliseconds: AppConstants.callConnectingDurationMs), () {
          if (controller.isClosed) return;
          controller.add(CallStatus.connected);
          _updateCallStatus(callId, CallStatus.connected,
              answeredAt: DateTime.now());
        });
      });
    });
  }

  void simulateIncomingCall({
    required String callId,
    required CallParticipant caller,
    required CallType type,
  }) {
    final controller = StreamController<CallStatus>.broadcast();
    _statusControllers[callId] = controller;
    _muteState[callId] = false;
    _speakerState[callId] = false;
    _cameraState[callId] = type == CallType.video;
    _frontCameraState[callId] = true;

    _activeCalls[callId] = Call(
      id: callId,
      caller: caller,
      receiver: CallParticipant(
        id: MockData.currentUserId,
        name: MockData.currentUser.name,
      ),
      type: type,
      status: CallStatus.ringing,
      direction: CallDirection.incoming,
      startedAt: DateTime.now(),
    );

    controller.add(CallStatus.ringing);
  }

  @override
  Future<void> acceptCall(String callId) async {
    final controller = _statusControllers[callId];
    if (controller == null || controller.isClosed) return;

    controller.add(CallStatus.connecting);
    _updateCallStatus(callId, CallStatus.connecting);

    await Future.delayed(
        const Duration(milliseconds: AppConstants.callConnectingDurationMs));

    if (controller.isClosed) return;
    controller.add(CallStatus.connected);
    _updateCallStatus(callId, CallStatus.connected,
        answeredAt: DateTime.now());
  }

  @override
  Future<void> rejectCall(String callId) async {
    final controller = _statusControllers[callId];
    if (controller == null || controller.isClosed) return;

    controller.add(CallStatus.rejected);
    _updateCallStatus(callId, CallStatus.rejected, endedAt: DateTime.now());

    await Future.delayed(const Duration(milliseconds: 500));
    _cleanupCall(callId);
  }

  @override
  Future<void> endCall(String callId) async {
    final controller = _statusControllers[callId];
    if (controller == null || controller.isClosed) return;

    controller.add(CallStatus.ended);
    _updateCallStatus(callId, CallStatus.ended, endedAt: DateTime.now());

    await Future.delayed(const Duration(milliseconds: 500));
    _cleanupCall(callId);
  }

  @override
  Future<void> toggleMute(String callId) async {
    _muteState[callId] = !(_muteState[callId] ?? false);
  }

  @override
  Future<void> toggleSpeaker(String callId) async {
    _speakerState[callId] = !(_speakerState[callId] ?? false);
  }

  @override
  Future<void> toggleCamera(String callId) async {
    _cameraState[callId] = !(_cameraState[callId] ?? true);
  }

  @override
  Future<void> switchCamera(String callId) async {
    _frontCameraState[callId] = !(_frontCameraState[callId] ?? true);
  }

  @override
  Stream<CallStatus> callStatusStream(String callId) {
    return _statusControllers[callId]?.stream ?? const Stream.empty();
  }

  @override
  Future<List<Call>> getCallHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(MockData.callHistory);
  }

  @override
  Future<Call?> getCallById(String callId) async {
    return _activeCalls[callId];
  }

  Call? getActiveCall(String callId) => _activeCalls[callId];

  void _updateCallStatus(String callId, CallStatus status,
      {DateTime? answeredAt, DateTime? endedAt}) {
    final call = _activeCalls[callId];
    if (call != null) {
      _activeCalls[callId] = call.copyWith(
        status: status,
        answeredAt: answeredAt ?? call.answeredAt,
        endedAt: endedAt ?? call.endedAt,
      );
    }
  }

  void _cleanupCall(String callId) {
    _statusControllers[callId]?.close();
    _statusControllers.remove(callId);
    _activeCalls.remove(callId);
    _muteState.remove(callId);
    _speakerState.remove(callId);
    _cameraState.remove(callId);
    _frontCameraState.remove(callId);
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    for (final controller in _statusControllers.values) {
      controller.close();
    }
    _statusControllers.clear();
    _activeCalls.clear();
  }
}
