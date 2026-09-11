import '../models/call.dart';
import '../models/call_status.dart';
import '../services/calling_service.dart';

class CallRepository {
  final CallingService _callingService;

  CallRepository(this._callingService);

  Future<void> startCall({
    required String callId,
    required String callerId,
    required String receiverId,
    required CallType type,
  }) =>
      _callingService.startCall(
        callId: callId,
        callerId: callerId,
        receiverId: receiverId,
        type: type,
      );

  Future<void> acceptCall(String callId, [CallType? type]) =>
      _callingService.acceptCall(callId, type);

  Future<void> rejectCall(String callId) =>
      _callingService.rejectCall(callId);

  Future<void> endCall(String callId) => _callingService.endCall(callId);

  Future<void> toggleMute(String callId) =>
      _callingService.toggleMute(callId);

  Future<void> toggleSpeaker(String callId) =>
      _callingService.toggleSpeaker(callId);

  Future<void> toggleCamera(String callId) =>
      _callingService.toggleCamera(callId);

  Future<void> switchCamera(String callId) =>
      _callingService.switchCamera(callId);

  Stream<CallStatus> callStatusStream(String callId) =>
      _callingService.callStatusStream(callId);

  Future<List<Call>> getCallHistory(String userId) =>
      _callingService.getCallHistory(userId);

  Future<Call?> getCallById(String callId) =>
      _callingService.getCallById(callId);

  void dispose() => _callingService.dispose();
}
