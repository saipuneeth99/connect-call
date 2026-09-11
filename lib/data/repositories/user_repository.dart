import '../models/app_user.dart';
import '../services/user_service.dart';

class UserRepository {
  final UserService _userService;

  UserRepository(this._userService);

  Future<List<AppUser>> getUsers() => _userService.getUsers();

  Future<List<AppUser>> searchUsers(String query) =>
      _userService.searchUsers(query);

  Future<AppUser?> getUserById(String id) => _userService.getUserById(id);

  Future<List<AppUser>> getFavorites(String userId) =>
      _userService.getFavorites(userId);

  Future<AppUser> updateUser(AppUser user) => _userService.updateUser(user);
}
