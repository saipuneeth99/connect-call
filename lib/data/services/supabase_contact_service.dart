import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../models/contact_request.dart';
import 'contact_service.dart';

class SupabaseContactService implements ContactService {
  final SupabaseClient _client;
  static const String _tableName = 'contact_requests';

  SupabaseContactService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<AppUser>> getContacts(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('status', 'accepted')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId');

      final rows = response as List;
      if (rows.isEmpty) return [];

      final contactIds = rows.map<String>((row) {
        final sender = row['sender_id'] as String;
        final receiver = row['receiver_id'] as String;
        return sender == userId ? receiver : sender;
      }).toSet().toList();

      if (contactIds.isEmpty) return [];

      // Query user profiles for all contact IDs
      final usersResponse = await _client
          .from('users')
          .select()
          .inFilter('id', contactIds);

      final userList = (usersResponse as List)
          .map((json) => AppUser.fromJson(json))
          .toList();

      return userList;
    } catch (e) {
      debugPrint('SupabaseContactService.getContacts error: $e');
      // If table doesn't exist yet, return empty list gracefully
      return [];
    }
  }

  @override
  Future<List<ContactRequest>> getIncomingRequests(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('receiver_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final rows = response as List;
      if (rows.isEmpty) return [];

      final senderIds =
          rows.map<String>((r) => r['sender_id'] as String).toSet().toList();

      final usersResponse = await _client
          .from('users')
          .select()
          .inFilter('id', senderIds);

      final userMap = {
        for (var u in (usersResponse as List).map((j) => AppUser.fromJson(j)))
          u.id: u
      };

      return rows.map((r) {
        final senderId = r['sender_id'] as String;
        return ContactRequest.fromJson(
          r as Map<String, dynamic>,
          sender: userMap[senderId],
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseContactService.getIncomingRequests error: $e');
      return [];
    }
  }

  @override
  Future<List<ContactRequest>> getSentRequests(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('sender_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final rows = response as List;
      if (rows.isEmpty) return [];

      final receiverIds =
          rows.map<String>((r) => r['receiver_id'] as String).toSet().toList();

      final usersResponse = await _client
          .from('users')
          .select()
          .inFilter('id', receiverIds);

      final userMap = {
        for (var u in (usersResponse as List).map((j) => AppUser.fromJson(j)))
          u.id: u
      };

      return rows.map((r) {
        final receiverId = r['receiver_id'] as String;
        return ContactRequest.fromJson(
          r as Map<String, dynamic>,
          receiver: userMap[receiverId],
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseContactService.getSentRequests error: $e');
      return [];
    }
  }

  @override
  Future<List<UserSearchResult>> searchUsersByEmail(
    String currentUserId,
    String emailQuery,
  ) async {
    final query = emailQuery.trim().toLowerCase();
    if (query.isEmpty) return [];

    try {
      // Find matching users from public.users table
      final response = await _client
          .from('users')
          .select()
          .ilike('email', '%$query%')
          .limit(15);

      final users = (response as List)
          .map((json) => AppUser.fromJson(json))
          .toList();

      if (users.isEmpty) return [];

      // Query relationship status with current user
      final relatedRows = await _client
          .from(_tableName)
          .select()
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId');

      final relationshipMap = <String, Map<String, dynamic>>{};
      for (final row in (relatedRows as List)) {
        final sender = row['sender_id'] as String;
        final receiver = row['receiver_id'] as String;
        final otherId = sender == currentUserId ? receiver : sender;
        relationshipMap[otherId] = row as Map<String, dynamic>;
      }

      return users.map((user) {
        if (user.id == currentUserId) {
          return UserSearchResult(
            user: user,
            relationship: UserRelationship.self,
          );
        }

        final relRow = relationshipMap[user.id];
        if (relRow == null) {
          return UserSearchResult(
            user: user,
            relationship: UserRelationship.none,
          );
        }

        final status = (relRow['status'] as String? ?? '').toLowerCase();
        final senderId = relRow['sender_id'] as String;
        final reqId = relRow['id'] as String?;

        if (status == 'accepted') {
          return UserSearchResult(
            user: user,
            relationship: UserRelationship.connected,
            requestId: reqId,
          );
        } else if (status == 'pending') {
          if (senderId == currentUserId) {
            return UserSearchResult(
              user: user,
              relationship: UserRelationship.requestSent,
              requestId: reqId,
            );
          } else {
            return UserSearchResult(
              user: user,
              relationship: UserRelationship.requestReceived,
              requestId: reqId,
            );
          }
        } else {
          return UserSearchResult(
            user: user,
            relationship: UserRelationship.none,
          );
        }
      }).toList();
    } catch (e) {
      debugPrint('SupabaseContactService.searchUsersByEmail error: $e');
      return [];
    }
  }

  @override
  Future<ContactRequest> sendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final id =
          'req_${DateTime.now().millisecondsSinceEpoch}_${senderId.substring(0, 4)}';
      final now = DateTime.now();

      final data = {
        'id': id,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'status': 'pending',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await _client.from(_tableName).upsert(
            data,
            onConflict: 'sender_id,receiver_id',
          );

      return ContactRequest(
        id: id,
        senderId: senderId,
        receiverId: receiverId,
        status: ContactRequestStatus.pending,
        createdAt: now,
      );
    } catch (e) {
      debugPrint('SupabaseContactService.sendRequest error: $e');
      throw ServerException('Failed to send contact request: $e');
    }
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    try {
      await _client.from(_tableName).update({
        'status': 'accepted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);
    } catch (e) {
      debugPrint('SupabaseContactService.acceptRequest error: $e');
      throw ServerException('Failed to accept contact request: $e');
    }
  }

  @override
  Future<void> declineOrCancelRequest(String requestId) async {
    try {
      await _client.from(_tableName).delete().eq('id', requestId);
    } catch (e) {
      debugPrint('SupabaseContactService.declineOrCancelRequest error: $e');
      throw ServerException('Failed to decline/cancel contact request: $e');
    }
  }

  @override
  Future<void> removeContact({
    required String currentUserId,
    required String contactUserId,
  }) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .or(
            'and(sender_id.eq.$currentUserId,receiver_id.eq.$contactUserId),'
            'and(sender_id.eq.$contactUserId,receiver_id.eq.$currentUserId)',
          );
    } catch (e) {
      debugPrint('SupabaseContactService.removeContact error: $e');
      throw ServerException('Failed to remove contact: $e');
    }
  }
}
