import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/livekit_config.dart';
import '../../core/utils/livekit_token_generator.dart';
import '../models/call.dart';
import '../models/call_participant.dart';
import '../models/call_status.dart';
import 'calling_service.dart';

class LiveKitCallingService implements CallingService {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  final Map<String, StreamController<CallStatus>> _statusControllers = {};
  final Map<String, Call> _activeCalls = {};
  Timer? _ringingTimer;
  bool _isSpeakerOn = false;

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

    String callerName = 'You';
    String receiverName = 'Remote User';
    try {
      if (Supabase.instance.isInitialized) {
        final users = await Supabase.instance.client
            .from('users')
            .select('id, name')
            .inFilter('id', [callerId, receiverId]);
        for (final u in (users as List)) {
          if (u['id'] == callerId && u['name'] != null) {
            callerName = u['name'] as String;
          }
          if (u['id'] == receiverId && u['name'] != null) {
            receiverName = u['name'] as String;
          }
        }
      }
    } catch (_) {}

    final call = Call(
      id: callId,
      caller: CallParticipant(id: callerId, name: callerName),
      receiver: CallParticipant(id: receiverId, name: receiverName),
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

      // Start audio playback engine and route audio appropriately
      try {
        await _room!.startAudio();
        final useSpeaker = type == CallType.video;
        await AudioManager.instance.setSpeakerOutputPreferred(useSpeaker, force: true);
        _isSpeakerOn = useSpeaker;
      } catch (e) {
        debugPrint('startCall audio setup error: $e');
      }

      // Publish mic
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      // Publish camera if video call
      if (type == CallType.video) {
        await _room!.localParticipant?.setCameraEnabled(true);
        _updateLocalTrack();
      }

      controller.add(CallStatus.ringing);
      _activeCalls[callId] = call.copyWith(
        status: CallStatus.ringing,
      );
      await _logCallToSupabase(_activeCalls[callId]!);

      // Ringing timeout (45 seconds) if unanswered
      _ringingTimer?.cancel();
      _ringingTimer = Timer(const Duration(seconds: 45), () {
        if (_activeCalls[callId]?.status == CallStatus.ringing) {
          controller.add(CallStatus.missed);
          _activeCalls[callId] = _activeCalls[callId]!.copyWith(
            status: CallStatus.missed,
            endedAt: DateTime.now(),
          );
          _logCallToSupabase(_activeCalls[callId]!);
          _cleanupRoom();
        }
      });
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
  Future<void> acceptCall(String callId, [CallType? type]) async {
    final controller = _getOrCreateStatusController(callId);
    controller.add(CallStatus.connecting);

    var call = _activeCalls[callId];
    call ??= await getCallById(callId);
    final effectiveType = type ?? call?.type ?? CallType.audio;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final receiverId = call?.receiver.id ?? currentUserId ?? 'receiver';

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

      // Start audio playback engine and route audio appropriately
      try {
        await _room!.startAudio();
        final useSpeaker = effectiveType == CallType.video;
        await AudioManager.instance.setSpeakerOutputPreferred(useSpeaker, force: true);
        _isSpeakerOn = useSpeaker;
      } catch (e) {
        debugPrint('acceptCall audio setup error: $e');
      }

      await _room!.localParticipant?.setMicrophoneEnabled(true);

      if (effectiveType == CallType.video) {
        await _room!.localParticipant?.setCameraEnabled(true);
        _updateLocalTrack();
      }

      _updateRemoteTrack();

      controller.add(CallStatus.connected);
      if (call != null) {
        _activeCalls[callId] = call.copyWith(
          status: CallStatus.connected,
          answeredAt: DateTime.now(),
        );
        await _logCallToSupabase(_activeCalls[callId]!);
      }
    } catch (e) {
      debugPrint('LiveKit acceptCall error: $e');
      controller.add(CallStatus.failed);
    }
  }

  @override
  Future<void> rejectCall(String callId) async {
    _ringingTimer?.cancel();
    _ringingTimer = null;
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
    _ringingTimer?.cancel();
    _ringingTimer = null;
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
    _isSpeakerOn = !_isSpeakerOn;
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(_isSpeakerOn);
    } catch (_) {}
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
            answeredAt: json['answered_at'] != null
                ? DateTime.parse(json['answered_at'] as String)
                : (json['duration_seconds'] != null &&
                        (json['duration_seconds'] as num) > 0
                    ? DateTime.parse(json['started_at'] as String)
                    : null),
            endedAt: json['ended_at'] != null
                ? DateTime.parse(json['ended_at'] as String)
                : null,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('LiveKit getCallHistory error: $e');
    }
    return [];
  }

  @override
  Future<Call?> getCallById(String callId) async {
    if (_activeCalls.containsKey(callId)) {
      return _activeCalls[callId];
    }
    try {
      if (Supabase.instance.isInitialized) {
        final res = await Supabase.instance.client
            .from('calls')
            .select()
            .eq('id', callId)
            .maybeSingle();
        if (res != null) {
          final call = Call(
            id: res['id'] as String,
            caller: CallParticipant(
              id: res['caller_id'] as String,
              name: (res['caller_name'] as String?) ?? 'Caller',
            ),
            receiver: CallParticipant(
              id: res['receiver_id'] as String,
              name: (res['receiver_name'] as String?) ?? 'Receiver',
            ),
            type: res['type'] == 'video' ? CallType.video : CallType.audio,
            status: CallStatus.values.firstWhere(
              (s) => s.name == res['status'],
              orElse: () => CallStatus.ended,
            ),
            direction: CallDirection.incoming,
            startedAt: DateTime.parse(res['started_at'] as String),
            answeredAt: res['answered_at'] != null
                ? DateTime.parse(res['answered_at'] as String)
                : null,
            endedAt: res['ended_at'] != null
                ? DateTime.parse(res['ended_at'] as String)
                : null,
          );
          _activeCalls[callId] = call;
          return call;
        }
      }
    } catch (e) {
      debugPrint('LiveKit getCallById supabase error: $e');
    }
    return null;
  }

  void _setupRoomListeners(String callId) {
    _listener = _room?.createListener();
    _listener
      ?..on<ParticipantConnectedEvent>((event) {
        _ringingTimer?.cancel();
        _ringingTimer = null;
        final ctrl = _getOrCreateStatusController(callId);
        ctrl.add(CallStatus.connected);
        if (_activeCalls[callId] != null) {
          _activeCalls[callId] = _activeCalls[callId]!.copyWith(
            status: CallStatus.connected,
            answeredAt: DateTime.now(),
          );
        }
        _updateRemoteTrack();
        try {
          _room?.startAudio();
        } catch (_) {}
      })
      ..on<TrackSubscribedEvent>((event) {
        if (event.track is VideoTrack) {
          remoteVideoTrackNotifier.value = event.track as VideoTrack;
        }
        try {
          _room?.startAudio();
        } catch (_) {}
      })
      ..on<TrackUnsubscribedEvent>((event) {
        if (event.track is VideoTrack) {
          _updateRemoteTrack();
        }
      })
      ..on<TrackMutedEvent>((event) {
        if (event.publication.kind == TrackType.VIDEO) {
          _updateRemoteTrack();
        }
      })
      ..on<TrackUnmutedEvent>((event) {
        if (event.publication.kind == TrackType.VIDEO) {
          _updateRemoteTrack();
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

  void _updateRemoteTrack() {
    if (_room == null) {
      remoteVideoTrackNotifier.value = null;
      return;
    }
    for (final participant in _room!.remoteParticipants.values) {
      for (final publication in participant.videoTrackPublications) {
        final track = publication.track;
        if (track != null && !publication.muted) {
          remoteVideoTrackNotifier.value = track;
          return;
        }
      }
    }
    remoteVideoTrackNotifier.value = null;
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
    _ringingTimer?.cancel();
    _ringingTimer = null;
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
        int durationSeconds = 0;
        if (call.endedAt != null) {
          if (call.answeredAt != null) {
            durationSeconds =
                call.endedAt!.difference(call.answeredAt!).inSeconds;
          } else if (call.status == CallStatus.connected ||
              call.status == CallStatus.ended) {
            durationSeconds =
                call.endedAt!.difference(call.startedAt).inSeconds;
          }
        }
        if (durationSeconds < 0) durationSeconds = 0;

        final payload = {
          'id': call.id,
          'caller_id': call.caller.id,
          'caller_name': call.caller.name,
          'receiver_id': call.receiver.id,
          'receiver_name': call.receiver.name,
          'type': call.type.name,
          'status': call.status.name,
          'started_at': call.startedAt.toIso8601String(),
          'ended_at': (call.endedAt ?? DateTime.now()).toIso8601String(),
          'duration_seconds': durationSeconds,
        };

        await Supabase.instance.client.from('calls').upsert(payload);
        debugPrint(
            'Call logged to Supabase successfully: ${call.id} ($durationSeconds s, status: ${call.status.name})');
      }
    } catch (e) {
      debugPrint('Error logging call to Supabase: $e');
    }
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
