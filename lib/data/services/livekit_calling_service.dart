import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/livekit_config.dart';
import '../../core/utils/livekit_token_generator.dart';
import '../../mock/mock_data.dart';
import '../models/call.dart';
import '../models/call_participant.dart';
import '../models/call_status.dart';
import 'calling_service.dart';

class LiveKitCallingService implements CallingService {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  final Map<String, StreamController<CallStatus>> _statusControllers = {};
  final Map<String, Call> _activeCalls = {};

  final ValueNotifier<LocalVideoTrack?> localVideoTrackNotifier =
      ValueNotifier<LocalVideoTrack?>(null);
  final ValueNotifier<VideoTrack?> remoteVideoTrackNotifier =
      ValueNotifier<VideoTrack?>(null);

  Room? get currentRoom => _room;

  @override
  Future<void> startCall({
    required String callId,
    required String callerId,
    required String receiverId,
    required CallType type,
  }) async {
    final controller = _getOrCreateStatusController(callId);
    controller.add(CallStatus.calling);

    final call = Call(
      id: callId,
      caller: CallParticipant(id: callerId, name: 'You'),
      receiver: CallParticipant(id: receiverId, name: 'Remote User'),
      type: type,
      status: CallStatus.calling,
      direction: CallDirection.outgoing,
      startedAt: DateTime.now(),
    );
    _activeCalls[callId] = call;

    try {
      final token = LiveKitTokenGenerator.createToken(
        roomName: callId,
        participantIdentity: callerId,
        participantName: callerId,
      );

      _room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultCameraCaptureOptions: CameraCaptureOptions(
            cameraPosition: CameraPosition.front,
          ),
        ),
      );

      _setupRoomListeners(callId);

      await _room!.connect(LiveKitConfig.url, token);

      // Publish mic
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      // Publish camera if video call
      if (type == CallType.video) {
        await _room!.localParticipant?.setCameraEnabled(true);
        _updateLocalTrack();
      }

      controller.add(CallStatus.connected);
      _activeCalls[callId] = call.copyWith(
        status: CallStatus.connected,
        answeredAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('LiveKit startCall error: $e');
      controller.add(CallStatus.failed);
      _activeCalls[callId] = call.copyWith(
        status: CallStatus.failed,
        endedAt: DateTime.now(),
      );
      await _logCallToSupabase(_activeCalls[callId]!);
    }
  }

  @override
  Future<void> acceptCall(String callId) async {
    final controller = _getOrCreateStatusController(callId);
    controller.add(CallStatus.connecting);

    final call = _activeCalls[callId];
    final receiverId = call?.receiver.id ?? 'receiver';

    try {
      final token = LiveKitTokenGenerator.createToken(
        roomName: callId,
        participantIdentity: receiverId,
        participantName: receiverId,
      );

      _room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );

      _setupRoomListeners(callId);

      await _room!.connect(LiveKitConfig.url, token);

      await _room!.localParticipant?.setMicrophoneEnabled(true);

      if (call?.type == CallType.video) {
        await _room!.localParticipant?.setCameraEnabled(true);
        _updateLocalTrack();
      }

      controller.add(CallStatus.connected);
      if (call != null) {
        _activeCalls[callId] = call.copyWith(
          status: CallStatus.connected,
          answeredAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('LiveKit acceptCall error: $e');
      controller.add(CallStatus.failed);
    }
  }

  @override
  Future<void> rejectCall(String callId) async {
    final controller = _getOrCreateStatusController(callId);
    controller.add(CallStatus.rejected);

    final call = _activeCalls[callId];
    if (call != null) {
      _activeCalls[callId] = call.copyWith(
        status: CallStatus.rejected,
        endedAt: DateTime.now(),
      );
      await _logCallToSupabase(_activeCalls[callId]!);
    }

    await _cleanupRoom();
  }

  @override
  Future<void> endCall(String callId) async {
    final controller = _getOrCreateStatusController(callId);
    controller.add(CallStatus.ended);

    final call = _activeCalls[callId];
    if (call != null) {
      final now = DateTime.now();
      final updated = call.copyWith(
        status: CallStatus.ended,
        endedAt: now,
      );
      _activeCalls[callId] = updated;
      await _logCallToSupabase(updated);
    }

    await _cleanupRoom();
  }

  @override
  Future<void> toggleMute(String callId) async {
    final local = _room?.localParticipant;
    if (local == null) return;
    final isEnabled = local.isMicrophoneEnabled();
    await local.setMicrophoneEnabled(!isEnabled);
  }

  @override
  Future<void> toggleSpeaker(String callId) async {
    // WebRTC handles default audio routing
  }

  @override
  Future<void> toggleCamera(String callId) async {
    final local = _room?.localParticipant;
    if (local == null) return;
    final isEnabled = local.isCameraEnabled();
    await local.setCameraEnabled(!isEnabled);
    _updateLocalTrack();
  }

  @override
  Future<void> switchCamera(String callId) async {
    final local = _room?.localParticipant;
    if (local == null) return;

    final pub = local.videoTrackPublications.firstOrNull;
    final track = pub?.track;
    if (track is LocalVideoTrack) {
      final options = track.currentOptions;
      if (options is CameraCaptureOptions) {
        final newPosition = options.cameraPosition == CameraPosition.front
            ? CameraPosition.back
            : CameraPosition.front;
        await track.setCameraPosition(newPosition);
        _updateLocalTrack();
      }
    }
  }

  @override
  Stream<CallStatus> callStatusStream(String callId) {
    return _getOrCreateStatusController(callId).stream;
  }

  @override
  Future<List<Call>> getCallHistory(String userId) async {
    try {
      bool hasSupabase = false;
      try {
        hasSupabase = Supabase.instance.isInitialized;
      } catch (_) {
        hasSupabase = false;
      }

      if (hasSupabase) {
        final data = await Supabase.instance.client
            .from('calls')
            .select()
            .or('caller_id.eq.$userId,receiver_id.eq.$userId')
            .order('started_at', ascending: false);

        return (data as List).map((json) {
          final isOutgoing = json['caller_id'] == userId;
          return Call(
            id: json['id'] as String,
            caller: CallParticipant(
              id: json['caller_id'] as String,
              name: (json['caller_name'] as String?) ?? 'Caller',
            ),
            receiver: CallParticipant(
              id: json['receiver_id'] as String,
              name: (json['receiver_name'] as String?) ?? 'Receiver',
            ),
            type: json['type'] == 'video' ? CallType.video : CallType.audio,
            status: CallStatus.values.firstWhere(
              (s) => s.name == json['status'],
              orElse: () => CallStatus.ended,
            ),
            direction:
                isOutgoing ? CallDirection.outgoing : CallDirection.incoming,
            startedAt: DateTime.parse(json['started_at'] as String),
            endedAt: json['ended_at'] != null
                ? DateTime.parse(json['ended_at'] as String)
                : null,
          );
        }).toList();
      }
    } catch (_) {}
    return List.from(MockData.callHistory);
  }

  @override
  Future<Call?> getCallById(String callId) async {
    return _activeCalls[callId];
  }

  void _setupRoomListeners(String callId) {
    _listener = _room?.createListener();
    _listener
      ?..on<TrackSubscribedEvent>((event) {
        if (event.track is VideoTrack) {
          remoteVideoTrackNotifier.value = event.track as VideoTrack;
        }
      })
      ..on<TrackUnsubscribedEvent>((event) {
        if (event.track is VideoTrack) {
          remoteVideoTrackNotifier.value = null;
        }
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        endCall(callId);
      })
      ..on<RoomDisconnectedEvent>((event) {
        remoteVideoTrackNotifier.value = null;
        localVideoTrackNotifier.value = null;
      });
  }

  void _updateLocalTrack() {
    final track =
        _room?.localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track is LocalVideoTrack) {
      localVideoTrackNotifier.value = track;
    } else {
      localVideoTrackNotifier.value = null;
    }
  }

  Future<void> _cleanupRoom() async {
    _listener?.dispose();
    _listener = null;
    await _room?.disconnect();
    await _room?.dispose();
    _room = null;
    localVideoTrackNotifier.value = null;
    remoteVideoTrackNotifier.value = null;
  }

  Future<void> _logCallToSupabase(Call call) async {
    try {
      bool hasSupabase = false;
      try {
        hasSupabase = Supabase.instance.isInitialized;
      } catch (_) {
        hasSupabase = false;
      }

      if (hasSupabase) {
        await Supabase.instance.client.from('calls').upsert({
          'id': call.id,
          'caller_id': call.caller.id,
          'caller_name': call.caller.name,
          'receiver_id': call.receiver.id,
          'receiver_name': call.receiver.name,
          'type': call.type.name,
          'status': call.status.name,
          'started_at': call.startedAt.toIso8601String(),
          'ended_at': call.endedAt?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'duration_seconds': call.duration?.inSeconds ?? 0,
        });
      }
    } catch (_) {}
  }

  StreamController<CallStatus> _getOrCreateStatusController(String callId) {
    return _statusControllers.putIfAbsent(
      callId,
      () => StreamController<CallStatus>.broadcast(),
    );
  }

  @override
  void dispose() {
    _cleanupRoom();
    for (final controller in _statusControllers.values) {
      controller.close();
    }
    _statusControllers.clear();
    _activeCalls.clear();
    localVideoTrackNotifier.dispose();
    remoteVideoTrackNotifier.dispose();
  }
}
