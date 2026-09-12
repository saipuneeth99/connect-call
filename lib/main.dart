import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'data/models/call_status.dart';
import 'data/services/call_signaling_service.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final data = message.data;
  final callId = data['callId']?.toString();
  final callerId = data['callerId']?.toString();
  if (callId == null ||
      callId.isEmpty ||
      callerId == null ||
      callerId.isEmpty) {
    return;
  }

  final type = data['callType']?.toString() == 'video'
      ? CallType.video
      : CallType.audio;
  final callerName = data['callerName']?.toString() ?? 'Incoming Call';
  await CallSignalingService.wakeAndNotifyIncoming(
    callerName: callerName,
    callType: type.name,
    callId: callId,
  );
  await CallSignalingService.showCallkitIncoming(
    callId: callId,
    callerName: callerName,
    callerAvatar: data['callerAvatar']?.toString(),
    callerId: callerId,
    callType: type.name,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    // ignore: deprecated_member_use
    anonKey: SupabaseConfig.anonKey,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const ConnectCallApp());
}
