import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/routes/app_routes.dart';
import '../models/app_user.dart';
import '../models/call_status.dart';
import '../../modules/calling/controllers/call_controller.dart';
import '../../modules/calling/bindings/calling_binding.dart';

class CallSignalingService {
  static const _voipChannel = MethodChannel(
    'com.connectcall.connect_call/voip',
  );

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

  /// Lets Android hand presentation over to the native foreground listener
  /// while the Flutter app is backgrounded. This avoids duplicate call UIs.
  static Future<void> setAppInForeground(bool isForeground) async {
    if (!Platform.isAndroid) return;
    try {
      await _voipChannel.invokeMethod('setAppInForeground', {
        'isForeground': isForeground,
      });
    } catch (_) {}
  }

  static Future<void> markCallConnected(String callId) async {
    try {
      await FlutterCallkitIncoming.setCallConnected(callId);
    } catch (_) {}
  }

  static Future<void> dismissVoipNotification() async {
    try {
      await _voipChannel.invokeMethod('dismissIncomingCall');
    } catch (_) {}
  }

  static Future<void> showCallkitIncoming({
    required String callId,
    required String callerName,
    String? callerAvatar,
    required String callerId,
    required String callType,
  }) async {
    try {
      final params = CallKitParams(
        id: callId,
        nameCaller: callerName,
        appName: 'ConnectCall',
        avatar: callerAvatar,
        handle: callerName,
        type: callType == 'video' ? 1 : 0,
        duration: 45000,
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: false,
          subtitle: 'Missed Call',
          callbackText: 'Call Back',
        ),
        extra: <String, dynamic>{
          'callId': callId,
          'callerId': callerId,
          'callerName': callerName,
          'callerAvatar': callerAvatar,
          'callType': callType,
        },
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0F141C',
          actionColor: '#10B981',
          textColor: '#FFFFFF',
          isShowFullLockedScreen: true,
          isImportant: true,
          isFullScreen: true,
          textAccept: 'Answer',
          textDecline: 'Decline',
        ),
        ios: const IOSParams(
          handleType: 'generic',
          supportsVideo: true,
          includesCallsInRecents: true,
          configureAudioSession: true,
        ),
      );
      await FlutterCallkitIncoming.showCallkitIncoming(params);
      debugPrint(
        'FlutterCallkitIncoming.showCallkitIncoming triggered for $callId',
      );
    } catch (e) {
      debugPrint('showCallkitIncoming error: $e');
    }
  }

  static Future<void> endAllCallkitCalls() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
  }

  static Future<void> enableProximitySensor() async {
    try {
      await _voipChannel.invokeMethod('enableProximitySensor');
      debugPrint('Proximity sensor enabled');
    } catch (e) {
      debugPrint('enableProximitySensor error: $e');
    }
  }

  static Future<void> disableProximitySensor() async {
    try {
      await _voipChannel.invokeMethod('disableProximitySensor');
      debugPrint('Proximity sensor disabled');
    } catch (e) {
      debugPrint('disableProximitySensor error: $e');
    }
  }

  static Future<void> startForegroundService([String? userId]) async {
    try {
      if (userId != null && userId.isNotEmpty) {
        await _voipChannel.invokeMethod('setUserId', {'userId': userId});
      }
      await _voipChannel.invokeMethod('startForegroundService', {
        'userId': userId,
      });
    } catch (_) {}
  }

  static Future<void> stopForegroundService() async {
    try {
      await _voipChannel.invokeMethod('stopForegroundService');
    } catch (_) {}
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await _voipChannel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _voipChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }

  static CallSignalingService? _instance;
  static CallSignalingService get instance =>
      _instance ??= CallSignalingService._();

  bool _isAppForeground = true;
  final Map<String, Map<String, dynamic>> _incomingCallData = {};
  StreamSubscription<String>? _fcmTokenSubscription;
  bool _pushTokensInitialized = false;

  CallSignalingService._() {
    WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
    _setupMethodCallHandler();
    _setupCallkitListener();
    setAppInForeground(true);
  }

  void _onLifecycleChanged(AppLifecycleState state) {
    final isForeground = state == AppLifecycleState.resumed;
    if (_isAppForeground == isForeground) return;
    _isAppForeground = isForeground;
    setAppInForeground(isForeground);
    if (isForeground) {
      _checkPendingCalls();
    }
  }

  void _setupMethodCallHandler() {
    _voipChannel.setMethodCallHandler((call) async {
      if (call.method == 'onCallDeclinedFromNotification') {
        debugPrint('Signaling: call declined from notification');
        try {
          if (Get.isRegistered<CallController>()) {
            Get.find<CallController>().rejectCall();
          }
        } catch (_) {}
      } else if (call.method == 'onCallAcceptedFromNotification') {
        debugPrint('Signaling: call accepted from notification');
        try {
          if (Get.isRegistered<CallController>()) {
            Get.find<CallController>().acceptCall();
          }
        } catch (_) {}
      } else if (call.method == 'navigateToIncomingCall') {
        debugPrint('Signaling: navigateToIncomingCall from native notification');
        if (Get.currentRoute != AppRoutes.incomingCall &&
            Get.currentRoute != AppRoutes.audioCall &&
            Get.currentRoute != AppRoutes.videoCall) {
          Get.toNamed(AppRoutes.incomingCall);
        }
      }
    });
  }

  StreamSubscription? _callkitSubscription;

  void _setupCallkitListener() {
    _callkitSubscription?.cancel();
    _callkitSubscription = FlutterCallkitIncoming.onEvent.listen((
      CallEvent? event,
    ) async {
      if (event == null) return;
      debugPrint('CallKit event received: ${event.eventName}');

      switch (event) {
        case CallEventActionDidUpdateDevicePushTokenVoip():
          final token = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
          if (token != null && token.isNotEmpty) {
            await _persistPushToken('voip_token', token);
          }
          break;

        case CallEventActionCallAccept(:final callKitParams):
          final extra = callKitParams.extra ?? {};
          final callId = (extra['callId'] as String?) ?? callKitParams.id;
          final callerId = extra['callerId'] as String?;
          final callerName =
              (extra['callerName'] as String?) ??
              callKitParams.nameCaller ??
              'Incoming Call';
          final callTypeStr = (extra['callType'] as String?) ?? 'audio';
          final callType = callTypeStr == 'video'
              ? CallType.video
              : CallType.audio;

          debugPrint('CallKit: Call accepted for $callId');
          dismissVoipNotification();
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
          break;

        case CallEventActionCallDecline(:final callKitParams):
          final extra = callKitParams.extra ?? {};
          final callId = (extra['callId'] as String?) ?? callKitParams.id;
          final callerId = extra['callerId'] as String?;

          debugPrint('CallKit: Call declined for $callId');
          dismissVoipNotification();
          if (callerId != null && callId.isNotEmpty) {
            sendReply(callerId: callerId, callId: callId, status: 'rejected');
            try {
              if (Supabase.instance.isInitialized) {
                await Supabase.instance.client
                    .from('calls')
                    .update({
                      'status': 'rejected',
                      'ended_at': DateTime.now().toIso8601String(),
                    })
                    .eq('id', callId);
              }
            } catch (_) {}
          }
          if (Get.isRegistered<CallController>()) {
            Get.find<CallController>().rejectCall();
          }
          break;

        case CallEventActionCallTimeout(:final id):
          debugPrint('CallKit: Call timeout for $id');
          dismissVoipNotification();
          final timeoutData = _incomingCallData.remove(id);
          final timeoutCallerId = timeoutData?['callerId'] as String?;
          if (timeoutCallerId != null) {
            sendReply(
              callerId: timeoutCallerId,
              callId: id,
              status: 'rejected',
            );
          }
          try {
            if (Supabase.instance.isInitialized) {
              await Supabase.instance.client
                  .from('calls')
                  .update({
                    'status': 'missed',
                    'ended_at': DateTime.now().toIso8601String(),
                  })
                  .eq('id', id);
            }
          } catch (_) {}
          break;

        case CallEventActionCallEnded():
          debugPrint('CallKit: Call ended');
          dismissVoipNotification();
          endAllCallkitCalls();
          if (Get.isRegistered<CallController>()) {
            Get.find<CallController>().endCall();
          }
          break;

        default:
          break;
      }
    });
  }

  RealtimeChannel? _myChannel;
  RealtimeChannel? _dbCallsChannel;
  Timer? _pendingCheckTimer;
  String? _lastHandledCallId;
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

    // Keep the native listener alive. Settings screens are never opened
    // implicitly during login; the app can request those permissions explicitly.
    startForegroundService(userId);
    if (Platform.isAndroid && _isAppForeground) {
      try {
        await FlutterCallkitIncoming.requestNotificationPermission({
          'title': 'Allow ConnectCall calls',
          'rationaleMessagePermission': 'Notifications are required to receive calls while ConnectCall is in the background.',
        });
        if (!await FlutterCallkitIncoming.canUseFullScreenIntent()) {
          await FlutterCallkitIncoming.requestFullIntentPermission();
        }
      } catch (_) {}
    }
    await _initPushTokens();
    _setupCallkitListener();

    try {
      if (!Supabase.instance.isInitialized) return;

      // 1. Broadcast channel for instantaneous socket signaling
      final channelName = 'user_signaling_$userId';
      _myChannel = Supabase.instance.client.channel(
        channelName,
        opts: const RealtimeChannelConfig(self: false),
      );

      _myChannel!.onBroadcast(
        event: 'call_invite',
        callback: (payload) {
          Future.microtask(() => _handleIncomingInvite(payload));
        },
      );

      _myChannel!.onBroadcast(
        event: 'call_reply',
        callback: (rawPayload) {
          final payload =
              (rawPayload['payload'] is Map
                  ? (rawPayload['payload'] as Map).cast<String, dynamic>()
                  : null) ??
              rawPayload;
          debugPrint('Signaling: received call_reply: $payload');
          Future.microtask(() => _replyController.add(payload));
        },
      );

      _myChannel!.onBroadcast(
        event: 'call_ended',
        callback: (rawPayload) {
          final payload =
              (rawPayload['payload'] is Map
                  ? (rawPayload['payload'] as Map).cast<String, dynamic>()
                  : null) ??
              rawPayload;
          debugPrint('Signaling: received call_ended: $payload');
          dismissVoipNotification();
          Future.microtask(() => _endController.add(payload));
        },
      );

      _myChannel!.subscribe();
      debugPrint('CallSignalingService subscribed to broadcast $channelName');

      // 2. Database Realtime listener for calls table changes
      _dbCallsChannel =
          Supabase.instance.client
              .channel('incoming_calls_db_$userId')
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'calls',
                callback: (payload) {
                  final record = payload.newRecord;
                  if (record.isNotEmpty &&
                      record['receiver_id'] == userId &&
                      record['status'] == 'ringing') {
                    debugPrint(
                      'Signaling: detected incoming call from Postgres change: ${record['id']}',
                    );
                    _handleIncomingCallFromRecord(record);
                  }
                },
              )
            ..subscribe();
      debugPrint('CallSignalingService subscribed to DB calls realtime');

      // 3. Fast periodic check for calls inserted while phone was sleeping / transitioning
      _pendingCheckTimer?.cancel();
      _pendingCheckTimer = Timer.periodic(const Duration(milliseconds: 2000), (
        _,
      ) {
        _checkPendingCalls();
      });
      _checkPendingCalls();
    } catch (e) {
      debugPrint('CallSignalingService init error: $e');
    }
  }

  Future<void> _initPushTokens() async {
    if (_pushTokensInitialized) return;
    _pushTokensInitialized = true;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _persistPushToken('fcm_token', token);
      }
      _fcmTokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) => _persistPushToken('fcm_token', token),
      );
    } catch (e) {
      debugPrint('FCM token registration unavailable: $e');
    }

    try {
      final voipToken = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
      if (voipToken != null && voipToken.isNotEmpty) {
        await _persistPushToken('voip_token', voipToken);
      }
    } catch (e) {
      debugPrint('VoIP token registration unavailable: $e');
    }
  }

  Future<void> _persistPushToken(String column, String token) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;
    try {
      if (Supabase.instance.isInitialized) {
        await Supabase.instance.client
            .from('users')
            .update({column: token})
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint('Push token persistence failed: $e');
    }
  }

  Future<void> _checkPendingCalls() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;
    try {
      if (!Supabase.instance.isInitialized) return;
      final threshold = DateTime.now()
          .toUtc()
          .subtract(const Duration(seconds: 120))
          .toIso8601String();

      final res = await Supabase.instance.client
          .from('calls')
          .select()
          .eq('receiver_id', _currentUserId!)
          .eq('status', 'ringing')
          .gte('started_at', threshold)
          .order('started_at', ascending: false)
          .limit(1);

      if (res.isNotEmpty) {
        final callRecord = res.first;
        _handleIncomingCallFromRecord(callRecord);
      }
    } catch (e) {
      // debugPrint('Check pending calls error: $e');
    }
  }

  void _handleIncomingCallFromRecord(Map<String, dynamic> record) {
    final callId = record['id'] as String?;
    if (callId == null || callId == _lastHandledCallId) return;

    final callerId = record['caller_id'] as String?;
    final callerName = (record['caller_name'] as String?) ?? 'Incoming Call';
    final typeStr = record['type'] as String?;
    if (callerId == null) return;

    _handleIncomingInvite({
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callType': typeStr ?? 'audio',
      'type': typeStr ?? 'audio',
    });
  }

  Future<RealtimeChannel> _getOrCreatePeerChannel(String peerId) async {
    final topic = 'user_signaling_$peerId';
    if (_peerChannels.containsKey(topic)) {
      return _peerChannels[topic]!;
    }
    final channel = Supabase.instance.client.channel(
      topic,
      opts: const RealtimeChannelConfig(self: false),
    );
    channel.subscribe();
    _peerChannels[topic] = channel;
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
        payload: {'callId': callId, 'status': status},
      );
      debugPrint(
        'Signaling: sent call_reply ($status) to user_signaling_$callerId',
      );
    } catch (e) {
      debugPrint('CallSignalingService sendReply error: $e');
    }
  }

  /// Sends call end event
  Future<void> sendEnd({
    required String otherUserId,
    required String callId,
  }) async {
    try {
      if (!Supabase.instance.isInitialized) return;

      final channel = await _getOrCreatePeerChannel(otherUserId);

      await channel.sendBroadcastMessage(
        event: 'call_ended',
        payload: {'callId': callId},
      );
      debugPrint('Signaling: sent call_ended to $otherUserId');
    } catch (e) {
      debugPrint('CallSignalingService sendEnd error: $e');
    }
  }

  void _handleIncomingInvite(Map<String, dynamic> rawPayload) {
    debugPrint('Signaling: received incoming call invite: $rawPayload');
    final payload =
        (rawPayload['payload'] is Map
            ? (rawPayload['payload'] as Map).cast<String, dynamic>()
            : null) ??
        rawPayload;
    final callId = payload['callId'] as String?;
    final callerId = payload['callerId'] as String?;
    final callerName = (payload['callerName'] as String?) ?? 'Unknown Caller';
    final callerAvatar = payload['callerAvatar'] as String?;
    final typeStr =
        (payload['callType'] as String?) ??
        (payload['type'] == 'broadcast' ? null : payload['type'] as String?);

    if (callId == null || callerId == null) return;
    if (_lastHandledCallId == callId &&
        Get.currentRoute == AppRoutes.incomingCall) {
      return;
    }
    _lastHandledCallId = callId;

    final type = typeStr == 'video' ? CallType.video : CallType.audio;

    _incomingCallData[callId] = {
      'callerId': callerId,
      'callerName': callerName,
      'callType': type.name,
    };

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
        (callCtrl.callStatus.value == CallStatus.ringing &&
            callCtrl.remoteUser.value?.id != callerId)) {
      // Line busy with another active call
      sendReply(callerId: callerId, callId: callId, status: 'busy');
      return;
    }

    callCtrl.setupIncomingCall(caller: caller, type: type, callId: callId);

    // 1. Always wake up the screen and show native high-priority heads up notification
    wakeAndNotifyIncoming(
      callerName: caller.name,
      callType: type.name,
    );

    // 2. Always trigger native CallKit incoming call UI (rings with real phone ringtone on lockscreen)
    showCallkitIncoming(
      callId: callId,
      callerName: caller.name,
      callerAvatar: caller.avatarUrl,
      callerId: caller.id,
      callType: type.name,
    );

    // 3. Dismiss any open sheets/dialogs before pushing incoming call view
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    // 4. Navigate to incoming call view
    if (Get.currentRoute != AppRoutes.incomingCall &&
        Get.currentRoute != AppRoutes.audioCall &&
        Get.currentRoute != AppRoutes.videoCall) {
      Get.toNamed(AppRoutes.incomingCall);
    }
  }

  Future<void> dispose() async {
    _pendingCheckTimer?.cancel();
    _pendingCheckTimer = null;
    _lastHandledCallId = null;
    await _fcmTokenSubscription?.cancel();
    _fcmTokenSubscription = null;
    _pushTokensInitialized = false;

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

    if (_dbCallsChannel != null) {
      try {
        await Supabase.instance.client.removeChannel(_dbCallsChannel!);
      } catch (_) {}
      _dbCallsChannel = null;
    }

    _currentUserId = null;
    disableProximitySensor();
    stopForegroundService();
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this.owner);

  final CallSignalingService owner;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    owner._onLifecycleChanged(state);
  }
}
