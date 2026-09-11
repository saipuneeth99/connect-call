import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../models/app_user.dart';
import 'user_service.dart';

class SupabaseUserService implements UserService {
  final SupabaseClient _client;

  SupabaseUserService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<AppUser>> getUsers() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .order('name', ascending: true);
      return (response as List).map((json) => AppUser.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch users: $e');
    }
  }

  @override
  Future<List<AppUser>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return await getUsers();
      final q = query.trim();
      final response = await _client
          .from('users')
          .select()
          .or('name.ilike.%$q%,email.ilike.%$q%')
          .order('name', ascending: true);
      return (response as List).map((json) => AppUser.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to search users: $e');
    }
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    try {
      final response =
          await _client.from('users').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return AppUser.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<List<AppUser>> getFavorites(String userId) async {
    try {
      final response =
          await _client.from('users').select().neq('id', userId).limit(5);
      return (response as List).map((json) => AppUser.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<AppUser> updateUser(AppUser user) async {
    try {
      await _client.from('users').upsert(user.toJson());
      return user;
    } catch (e) {
      throw ServerException('Failed to update user: $e');
    }
  }

  /// Syncs an authenticated user from Firebase Auth into Supabase
  Future<void> syncUser(AppUser user) async {
    try {
      await _client.from('users').upsert(
            user.toJson(),
            onConflict: 'id',
          );
    } catch (_) {
      // Ignore sync failure during offline / test
    }
  }
}
