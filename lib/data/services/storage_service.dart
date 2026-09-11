abstract class StorageService {
  Future<String?> uploadAvatar(String userId, List<int> bytes, String fileName);
  Future<String?> getAvatarUrl(String userId);
  Future<void> deleteAvatar(String userId);
}
