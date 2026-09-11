import '../data/models/app_user.dart';
import '../data/services/user_service.dart';
import 'mock_data.dart';

class MockUserService implements UserService {
  @override
  Future<List<AppUser>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(MockData.users);
  }

  @override
  Future<List<AppUser>> searchUsers(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (query.trim().isEmpty) return List.from(MockData.users);

    final lowerQuery = query.toLowerCase();
    return MockData.users
        .where((user) =>
            user.name.toLowerCase().contains(lowerQuery) ||
            user.email.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return MockData.users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AppUser>> getFavorites(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(MockData.favorites);
  }

  @override
  Future<AppUser> updateUser(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return user;
  }
}
