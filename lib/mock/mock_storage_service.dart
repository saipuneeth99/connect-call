import '../data/services/storage_service.dart';

class MockStorageService implements StorageService {
  final Map<String, String> _avatars = {};

  @override
  Future<String?> uploadAvatar(
      String userId, List<int> bytes, String fileName) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final url = 'mock://avatars/$userId/$fileName';
    _avatars[userId] = url;
    return url;
  }

  @override
  Future<String?> getAvatarUrl(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _avatars[userId];
  }

  @override
  Future<void> deleteAvatar(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _avatars.remove(userId);
  }
}
