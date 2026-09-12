import 'app_user.dart';

enum ContactRequestStatus { pending, accepted, declined }

enum UserRelationship {
  none,
  self,
  requestSent,
  requestReceived,
  connected,
}

class ContactRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final ContactRequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final AppUser? sender;
  final AppUser? receiver;

  const ContactRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.sender,
    this.receiver,
  });

  ContactRequest copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    ContactRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    AppUser? sender,
    AppUser? receiver,
  }) {
    return ContactRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ContactRequest.fromJson(
    Map<String, dynamic> json, {
    AppUser? sender,
    AppUser? receiver,
  }) {
    final statusStr = json['status'] as String? ?? 'pending';
    ContactRequestStatus status;
    switch (statusStr.toLowerCase()) {
      case 'accepted':
        status = ContactRequestStatus.accepted;
        break;
      case 'declined':
        status = ContactRequestStatus.declined;
        break;
      default:
        status = ContactRequestStatus.pending;
    }

    return ContactRequest(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      status: status,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      sender: sender ??
          (json['sender'] != null && json['sender'] is Map<String, dynamic>
              ? AppUser.fromJson(json['sender'] as Map<String, dynamic>)
              : null),
      receiver: receiver ??
          (json['receiver'] != null && json['receiver'] is Map<String, dynamic>
              ? AppUser.fromJson(json['receiver'] as Map<String, dynamic>)
              : null),
    );
  }
}

class UserSearchResult {
  final AppUser user;
  final UserRelationship relationship;
  final String? requestId;

  const UserSearchResult({
    required this.user,
    required this.relationship,
    this.requestId,
  });

  UserSearchResult copyWith({
    AppUser? user,
    UserRelationship? relationship,
    String? requestId,
  }) {
    return UserSearchResult(
      user: user ?? this.user,
      relationship: relationship ?? this.relationship,
      requestId: requestId ?? this.requestId,
    );
  }
}
