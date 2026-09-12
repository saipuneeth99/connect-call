import '../data/models/app_user.dart';
import '../data/models/contact_request.dart';
import '../data/services/contact_service.dart';

class MockContactService implements ContactService {
  final List<ContactRequest> _requests = [];
  final List<AppUser> _registeredUsers = [
    const AppUser(
      id: 'user_1',
      name: 'Sarah Jenkins',
      email: 'sarah@example.com',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
      isOnline: true,
    ),
    const AppUser(
      id: 'user_2',
      name: 'Alex Rivera',
      email: 'alex@example.com',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
      isOnline: true,
    ),
    const AppUser(
      id: 'user_3',
      name: 'Priya Sharma',
      email: 'priya@example.com',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      isOnline: true,
    ),
  ];

  void addMockUser(AppUser user) {
    _registeredUsers.removeWhere((u) => u.id == user.id);
    _registeredUsers.add(user);
  }

  @override
  Future<List<AppUser>> getContacts(String userId) async {
    final acceptedRequests = _requests
        .where((r) =>
            r.status == ContactRequestStatus.accepted &&
            (r.senderId == userId || r.receiverId == userId))
        .toList();

    final contactIds = acceptedRequests.map((r) {
      return r.senderId == userId ? r.receiverId : r.senderId;
    }).toSet();

    return _registeredUsers.where((u) => contactIds.contains(u.id)).toList();
  }

  @override
  Future<List<ContactRequest>> getIncomingRequests(String userId) async {
    return _requests
        .where((r) =>
            r.receiverId == userId &&
            r.status == ContactRequestStatus.pending)
        .map((r) {
      final sender = _registeredUsers.firstWhere(
        (u) => u.id == r.senderId,
        orElse: () => AppUser(id: r.senderId, name: 'User', email: ''),
      );
      return r.copyWith(sender: sender);
    }).toList();
  }

  @override
  Future<List<ContactRequest>> getSentRequests(String userId) async {
    return _requests
        .where((r) =>
            r.senderId == userId &&
            r.status == ContactRequestStatus.pending)
        .map((r) {
      final receiver = _registeredUsers.firstWhere(
        (u) => u.id == r.receiverId,
        orElse: () => AppUser(id: r.receiverId, name: 'User', email: ''),
      );
      return r.copyWith(receiver: receiver);
    }).toList();
  }

  @override
  Future<List<UserSearchResult>> searchUsersByEmail(
    String currentUserId,
    String emailQuery,
  ) async {
    final query = emailQuery.trim().toLowerCase();
    if (query.isEmpty) return [];

    final matches = _registeredUsers
        .where((u) => u.email.toLowerCase().contains(query))
        .toList();

    return matches.map((user) {
      if (user.id == currentUserId) {
        return UserSearchResult(
          user: user,
          relationship: UserRelationship.self,
        );
      }

      final existing = _requests.firstWhere(
        (r) =>
            (r.senderId == currentUserId && r.receiverId == user.id) ||
            (r.senderId == user.id && r.receiverId == currentUserId),
        orElse: () => ContactRequest(
          id: '',
          senderId: '',
          receiverId: '',
          status: ContactRequestStatus.declined,
          createdAt: DateTime.now(),
        ),
      );

      if (existing.id.isEmpty) {
        return UserSearchResult(
          user: user,
          relationship: UserRelationship.none,
        );
      }

      if (existing.status == ContactRequestStatus.accepted) {
        return UserSearchResult(
          user: user,
          relationship: UserRelationship.connected,
          requestId: existing.id,
        );
      } else if (existing.status == ContactRequestStatus.pending) {
        if (existing.senderId == currentUserId) {
          return UserSearchResult(
            user: user,
            relationship: UserRelationship.requestSent,
            requestId: existing.id,
          );
        } else {
          return UserSearchResult(
            user: user,
            relationship: UserRelationship.requestReceived,
            requestId: existing.id,
          );
        }
      } else {
        return UserSearchResult(
          user: user,
          relationship: UserRelationship.none,
        );
      }
    }).toList();
  }

  @override
  Future<ContactRequest> sendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    _requests.removeWhere((r) =>
        (r.senderId == senderId && r.receiverId == receiverId) ||
        (r.senderId == receiverId && r.receiverId == senderId));

    final newReq = ContactRequest(
      id: 'mock_req_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      receiverId: receiverId,
      status: ContactRequestStatus.pending,
      createdAt: DateTime.now(),
    );
    _requests.add(newReq);
    return newReq;
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _requests[idx] = _requests[idx].copyWith(
        status: ContactRequestStatus.accepted,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> declineOrCancelRequest(String requestId) async {
    _requests.removeWhere((r) => r.id == requestId);
  }

  @override
  Future<void> removeContact({
    required String currentUserId,
    required String contactUserId,
  }) async {
    _requests.removeWhere((r) =>
        (r.senderId == currentUserId && r.receiverId == contactUserId) ||
        (r.senderId == contactUserId && r.receiverId == currentUserId));
  }
}
