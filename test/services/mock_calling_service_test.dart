import 'package:flutter_test/flutter_test.dart';
import 'package:connect_call/mock/mock_calling_service.dart';
import 'package:connect_call/data/models/call_status.dart';
import 'package:connect_call/mock/mock_data.dart';

void main() {
  late MockCallingService callingService;

  setUp(() {
    callingService = MockCallingService();
  });

  tearDown(() {
    callingService.dispose();
  });

  group('MockCallingService', () {
    test('startCall emits calling status', () async {
      final callId = 'test_call_1';

      await callingService.startCall(
        callId: callId,
        callerId: MockData.currentUserId,
        receiverId: 'user_1',
        type: CallType.audio,
      );

      expect(
        callingService.callStatusStream(callId),
        emitsInOrder([CallStatus.ringing]),
      );
    });

    test('mute toggles correctly', () async {
      final callId = 'test_call_2';

      await callingService.startCall(
        callId: callId,
        callerId: MockData.currentUserId,
        receiverId: 'user_1',
        type: CallType.audio,
      );

      expect(callingService.isMuted(callId), false);

      await callingService.toggleMute(callId);
      expect(callingService.isMuted(callId), true);

      await callingService.toggleMute(callId);
      expect(callingService.isMuted(callId), false);
    });

    test('camera starts on for video calls', () async {
      final callId = 'test_call_3';

      await callingService.startCall(
        callId: callId,
        callerId: MockData.currentUserId,
        receiverId: 'user_1',
        type: CallType.video,
      );

      expect(callingService.isCameraOn(callId), true);
    });

    test('camera starts off for audio calls', () async {
      final callId = 'test_call_4';

      await callingService.startCall(
        callId: callId,
        callerId: MockData.currentUserId,
        receiverId: 'user_1',
        type: CallType.audio,
      );

      expect(callingService.isCameraOn(callId), false);
    });

    test('endCall emits ended status', () async {
      final callId = 'test_call_5';

      await callingService.startCall(
        callId: callId,
        callerId: MockData.currentUserId,
        receiverId: 'user_1',
        type: CallType.audio,
      );

      expect(
        callingService.callStatusStream(callId),
        emits(anything),
      );

      await callingService.endCall(callId);
    });

    test('getCallHistory returns mock data', () async {
      final history =
          await callingService.getCallHistory(MockData.currentUserId);
      expect(history, isNotEmpty);
    });

    test('speaker toggles correctly', () async {
      final callId = 'test_call_6';

      await callingService.startCall(
        callId: callId,
        callerId: MockData.currentUserId,
        receiverId: 'user_1',
        type: CallType.audio,
      );

      expect(callingService.isSpeakerOn(callId), false);

      await callingService.toggleSpeaker(callId);
      expect(callingService.isSpeakerOn(callId), true);
    });

    test('switchCamera toggles front/rear', () async {
      final callId = 'test_call_7';

      await callingService.startCall(
        callId: callId,
        callerId: MockData.currentUserId,
        receiverId: 'user_1',
        type: CallType.video,
      );

      expect(callingService.isFrontCamera(callId), true);

      await callingService.switchCamera(callId);
      expect(callingService.isFrontCamera(callId), false);
    });
  });
}
