import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/routes/app_routes.dart';
import '../models/app_user.dart';
import '../models/call_status.dart';
import '../../modules/calling/controllers/call_controller.dart';
import '../../modules/calling/bindings/calling_binding.dart';

class CallSignalingService {
  static const _voipChannel = MethodChannel('com.connectcall.connect_call/voip');

  static Future<void> wakeAndNotifyIncoming({
    required String callerName,
    required String callType,
  }) async {
    try {
      await _voipChannel.invokeMethod('showIncomingCall', {
        'callerName': callerName,
        'callType': callType,
      });
    } catch (e) {
      debugPrint('Voip channel error: $e');
    }
  }

  static Future<void> dismissVoipNotification() async {
    try {
      await _voipChannel.invokeMethod('dismissIncomingCall');
    } catch (_) {}
  }

  static CallSignalingService? _instance;
  static CallSignalingService get instance =>
      _instance ??= CallSignalingService._();

  CallSignalingService._();

  RealtimeChannel? _myChannel;
  String? _currentUserId;
  final Map<String, RealtimeChannel> _peerChannels = {};

  // Stream of replies for callers awaiting an answer
  final _replyController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCallReply => _replyController.stream;

  // Stream of call end events from remote
  final _endController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCallEnded => _endController.stream;

  /// Initializes signaling for the currently authenticated user
  Future<void> init(String userId) async {
    if (_currentUserId == userId && _myChannel != null) {
      return;
    }

    await dispose();
    _currentUserId = userId;

    try {
      if (!Supabase.instance.isInitialized) return;

      final channelName = 'user_signaling_$userId';
      _myChannel = Supabase.instance.client.channel(
        channelName,
        opts: const RealtimeChannelConfig(self: false),
      );

      // Listen for incoming call invites
      _myChannel!.onBroadcast(
        event: 'call_invite',
        callback: (payload) {
          // Wrap in microtask to avoid modifying RealtimeClient.channels during iteration
          Future.microtask(() => _handleIncomingInvite(payload));
        },
      );

      // Listen for call replies (accepted / rejected / busy)
      _myChannel!.onBroadcast(
        event: 'call_reply',
        callback: (rawPayload) {
          final payload = (rawPayload['payload'] is Map
                  ? (rawPayload['payload'] as Map).cast<String, dynamic>()
                  : null) ??
              rawPayload;
          debugPrint('Signaling: received call_reply: $payload');
          Future.microtask(() => _replyController.add(payload));
        },
      );

      // Listen for remote call termination
      _myChannel!.onBroadcast(
        event: 'call_ended',
        callback: (rawPayload) {
          final payload = (rawPayload['payload'] is Map
                  ? (rawPayload['payload'] as Map).cast<String, dynamic>()
                  : null) ??
              rawPayload;
          debugPrint('Signaling: received call_ended: $payload');
          Future.microtask(() => _endController.add(payload));
        },
      );

      _myChannel!.subscribe();
      debugPrint('CallSignalingService subscribed to $channelName');
    } catch (e) {
      debugPrint('CallSignalingService init error: $e');
    }
  }

  Future<RealtimeChannel> _getOrCreatePeerChannel(String peerId) async {
    final topic = 'user_signaling_$peerId';
    if (_peerChannels.containsKey(topic)) {
      return _peerChannels[topic]!;
    }
    final channel = Supabase.instance.client.channel(
      topic,
      opts: const RealtimeChannelConfig(self: true),
    );
    channel.subscribe();
    _peerChannels[topic] = channel;
    // Allow phoenix socket connection to establish
    await Future.delayed(const Duration(milliseconds: 300));
    return channel;
  }

  /// Sends a call invitation to the recipient
  Future<void> sendInvite({
    required String receiverId,
    required String callId,
    required AppUser caller,
    required CallType type,
  }) async {
    try {
      if (!Supabase.instance.isInitialized) return;

      final channel = await _getOrCreatePeerChannel(receiverId);

      await channel.sendBroadcastMessage(
        event: 'call_invite',
        payload: {
          'callId': callId,
          'callerId': caller.id,
          'callerName': caller.name,
          'callerAvatar': caller.avatarUrl,
          'callType': type.name,
          'type': type.name,
        },
      );
      debugPrint('Signaling: sent call_invite to user_signaling_$receiverId');
    } catch (e) {
      debugPrint('CallSignalingService sendInvite error: $e');
    }
  }

  /// Sends accept / reject / busy status back to caller
  Future<void> sendReply({
    required String callerId,
    required String callId,
    required String status, // 'accepted' | 'rejected' | 'busy'
  }) async {
    try {
      if (!Supabase.instance.isInitialized) return;

      final channel = await _getOrCreatePeerChannel(callerId);

      await channel.sendBroadcastMessage(
        event: 'call_reply',
        payload: {
          'callId': callId,
          'status': status,
        },
      );
      debugPrint('Signaling: sent call_reply ($status) to $callerId');
    } catch (e) {
      debugPrint('CallSignalingService sendReply error: $e');
    }
  }

  /// Sends call ended signal to remote participant
  Future<void> sendEnd({
    required String otherUserId,
    required String callId,
  }) async {
    try {
      if (!Supabase.instance.isInitialized) return;

      final channel = await _getOrCreatePeerChannel(otherUserId);

      await channel.sendBroadcastMessage(
        event: 'call_ended',
        payload: {
          'callId': callId,
        },
      );
      debugPrint('Signaling: sent call_ended to $otherUserId');
    } catch (e) {
      debugPrint('CallSignalingService sendEnd error: $e');
    }
  }

  void _handleIncomingInvite(Map<String, dynamic> rawPayload) {
    debugPrint('Signaling: received incoming call invite: $rawPayload');
    final payload = (rawPayload['payload'] is Map
            ? (rawPayload['payload'] as Map).cast<String, dynamic>()
            : null) ??
        rawPayload;
    final callId = payload['callId'] as String?;
    final callerId = payload['callerId'] as String?;
    final callerName = (payload['callerName'] as String?) ?? 'Unknown Caller';
    final callerAvatar = payload['callerAvatar'] as String?;
    final typeStr = (payload['callType'] as String?) ??
        (payload['type'] == 'broadcast' ? null : payload['type'] as String?);

    if (callId == null || callerId == null) return;

    final type =
        typeStr == 'video' ? CallType.video : CallType.audio;

    final caller = AppUser(
      id: callerId,
      name: callerName,
      email: '',
      avatarUrl: callerAvatar,
      isOnline: true,
    );

    // Ensure CallingBinding is loaded
    CallingBinding().dependencies();
    final callCtrl = Get.find<CallController>();

    if (callCtrl.callStatus.value == CallStatus.connected ||
        callCtrl.callStatus.value == CallStatus.calling ||
        callCtrl.callStatus.value == CallStatus.ringing) {
      // Line busy
      sendReply(callerId: callerId, callId: callId, status: 'busy');
      return;
    }

    callCtrl.setupIncomingCall(
      caller: caller,
      type: type,
      callId: callId,
    );

    // Trigger full screen notification and screen wake-up
    wakeAndNotifyIncoming(
      callerName: caller.name,
      callType: type.name,
    );

    // Dismiss any open sheets/dialogs before pushing incoming call view
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    // Navigate to incoming call view
    if (Get.currentRoute != AppRoutes.incomingCall) {
      Get.toNamed(AppRoutes.incomingCall);
    }
  }

  Future<void> dispose() async {
    dismissVoipNotification();
    for (final ch in _peerChannels.values) {
      try {
        await Supabase.instance.client.removeChannel(ch);
      } catch (_) {}
    }
    _peerChannels.clear();

    if (_myChannel != null) {
      try {
        await Supabase.instance.client.removeChannel(_myChannel!);
      } catch (_) {}
      _myChannel = null;
    }
    _currentUserId = null;
  }
}
