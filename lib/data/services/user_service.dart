import '../models/app_user.dart';

abstract class UserService {
  Future<List<AppUser>> getUsers();
  Future<List<AppUser>> searchUsers(String query);
  Future<AppUser?> getUserById(String id);
  Future<List<AppUser>> getFavorites(String userId);
  Future<AppUser> updateUser(AppUser user);
}
