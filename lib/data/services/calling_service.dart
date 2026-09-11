import '../models/call.dart';
import '../models/call_status.dart';

abstract class CallingService {
  Future<void> startCall({
    required String callId,
    required String callerId,
    required String receiverId,
    required CallType type,
  });
  Future<void> acceptCall(String callId);
  Future<void> rejectCall(String callId);
  Future<void> endCall(String callId);
  Future<void> toggleMute(String callId);
  Future<void> toggleSpeaker(String callId);
  Future<void> toggleCamera(String callId);
  Future<void> switchCamera(String callId);
  Stream<CallStatus> callStatusStream(String callId);
  Future<List<Call>> getCallHistory(String userId);
  Future<Call?> getCallById(String callId);
  void dispose();
}
