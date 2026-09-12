import '../models/app_user.dart';
import '../models/contact_request.dart';

abstract class ContactService {
  /// Gets list of mutual accepted contacts for a user
  Future<List<AppUser>> getContacts(String userId);

  /// Gets list of incoming pending requests for a user
  Future<List<ContactRequest>> getIncomingRequests(String userId);

  /// Gets list of sent pending requests by a user
  Future<List<ContactRequest>> getSentRequests(String userId);

  /// Searches users by email, returning their contact relationship status relative to current user
  Future<List<UserSearchResult>> searchUsersByEmail(
    String currentUserId,
    String emailQuery,
  );

  /// Sends a contact request from senderId to receiverId
  Future<ContactRequest> sendRequest({
    required String senderId,
    required String receiverId,
  });

  /// Accepts a contact request
  Future<void> acceptRequest(String requestId);

  /// Declines or cancels a contact request
  Future<void> declineOrCancelRequest(String requestId);

  /// Removes an accepted contact connection between two users
  Future<void> removeContact({
    required String currentUserId,
    required String contactUserId,
  });
}
