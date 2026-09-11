import 'package:flutter_test/flutter_test.dart';
import 'package:connect_call/mock/mock_storage_service.dart';

void main() {
  late MockStorageService storageService;

  setUp(() {
    storageService = MockStorageService();
  });

  group('MockStorageService', () {
    test('uploadAvatar returns valid url and stores it', () async {
      final url = await storageService.uploadAvatar(
        'user_123',
        [1, 2, 3],
        'avatar.jpg',
      );

      expect(url, isNotNull);
      expect(url, contains('user_123'));

      final retrieved = await storageService.getAvatarUrl('user_123');
      expect(retrieved, equals(url));
    });

    test('deleteAvatar removes avatar url', () async {
      await storageService.uploadAvatar('user_123', [1, 2, 3], 'avatar.jpg');
      await storageService.deleteAvatar('user_123');

      final retrieved = await storageService.getAvatarUrl('user_123');
      expect(retrieved, isNull);
    });
  });
}
