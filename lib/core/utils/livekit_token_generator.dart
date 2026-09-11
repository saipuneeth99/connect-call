import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../config/livekit_config.dart';

class LiveKitTokenGenerator {
  LiveKitTokenGenerator._();

  static String createToken({
    required String roomName,
    required String participantIdentity,
    String? participantName,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final jwt = JWT(
      {
        'sub': participantIdentity,
        'name': participantName ?? participantIdentity,
        'iss': LiveKitConfig.apiKey,
        'nbf': now - 5,
        'exp': now + (24 * 3600), // 24 hours
        'video': {
          'room': roomName,
          'roomJoin': true,
          'canPublish': true,
          'canSubscribe': true,
          'canPublishData': true,
        },
      },
      issuer: LiveKitConfig.apiKey,
    );

    return jwt.sign(
      SecretKey(LiveKitConfig.apiSecret),
      algorithm: JWTAlgorithm.HS256,
    );
  }
}
