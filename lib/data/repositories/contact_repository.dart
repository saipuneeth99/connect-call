import '../models/app_user.dart';
import '../models/contact_request.dart';
import '../services/contact_service.dart';

class ContactRepository {
  final ContactService _service;

  ContactRepository(this._service);

  Future<List<AppUser>> getContacts(String userId) =>
      _service.getContacts(userId);

  Future<List<ContactRequest>> getIncomingRequests(String userId) =>
      _service.getIncomingRequests(userId);

  Future<List<ContactRequest>> getSentRequests(String userId) =>
      _service.getSentRequests(userId);

  Future<List<UserSearchResult>> searchUsersByEmail(
    String currentUserId,
    String emailQuery,
  ) =>
      _service.searchUsersByEmail(currentUserId, emailQuery);

  Future<ContactRequest> sendRequest({
    required String senderId,
    required String receiverId,
  }) =>
      _service.sendRequest(senderId: senderId, receiverId: receiverId);

  Future<void> acceptRequest(String requestId) =>
      _service.acceptRequest(requestId);

  Future<void> declineOrCancelRequest(String requestId) =>
      _service.declineOrCancelRequest(requestId);

  Future<void> removeContact({
    required String currentUserId,
    required String contactUserId,
  }) =>
      _service.removeContact(
        currentUserId: currentUserId,
        contactUserId: contactUserId,
      );
}
