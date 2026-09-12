import 'package:flutter_test/flutter_test.dart';
import 'package:connect_call/data/models/app_user.dart';
import 'package:connect_call/data/models/contact_request.dart';
import 'package:connect_call/mock/mock_contact_service.dart';

void main() {
  late MockContactService service;

  setUp(() {
    service = MockContactService();
  });

  group('MockContactService', () {
    test('User starts with 0 contacts', () async {
      final contacts = await service.getContacts('user_test');
      expect(contacts, isEmpty);
    });

    test('Search by email finds registered user with relationship none', () async {
      final results = await service.searchUsersByEmail('user_test', 'sarah');
      expect(results, isNotEmpty);
      expect(results.first.user.name, 'Sarah Jenkins');
      expect(results.first.relationship, UserRelationship.none);
    });

    test('Sending request updates relationship to requestSent', () async {
      final req = await service.sendRequest(
        senderId: 'user_test',
        receiverId: 'user_1',
      );

      expect(req.senderId, 'user_test');
      expect(req.receiverId, 'user_1');
      expect(req.status, ContactRequestStatus.pending);

      final sent = await service.getSentRequests('user_test');
      expect(sent.length, 1);
      expect(sent.first.receiverId, 'user_1');

      final incomingForReceiver = await service.getIncomingRequests('user_1');
      expect(incomingForReceiver.length, 1);
      expect(incomingForReceiver.first.senderId, 'user_test');

      final searchResults = await service.searchUsersByEmail('user_test', 'sarah');
      expect(searchResults.first.relationship, UserRelationship.requestSent);
    });

    test('Accepting request mutually connects both users and adds them to contacts', () async {
      final req = await service.sendRequest(
        senderId: 'user_test',
        receiverId: 'user_1',
      );

      service.addMockUser(const AppUser(
        id: 'user_test',
        name: 'Tester',
        email: 'tester@example.com',
      ));

      await service.acceptRequest(req.id);

      final senderContacts = await service.getContacts('user_test');
      expect(senderContacts.length, 1);
      expect(senderContacts.first.id, 'user_1');

      final receiverContacts = await service.getContacts('user_1');
      expect(receiverContacts.length, 1);
      expect(receiverContacts.first.id, 'user_test');

      final searchResults = await service.searchUsersByEmail('user_test', 'sarah');
      expect(searchResults.first.relationship, UserRelationship.connected);
    });

    test('Removing contact severs mutual connection', () async {
      final req = await service.sendRequest(
        senderId: 'user_test',
        receiverId: 'user_1',
      );
      service.addMockUser(const AppUser(
        id: 'user_test',
        name: 'Tester',
        email: 'tester@example.com',
      ));
      await service.acceptRequest(req.id);

      await service.removeContact(
        currentUserId: 'user_test',
        contactUserId: 'user_1',
      );

      final contacts = await service.getContacts('user_test');
      expect(contacts, isEmpty);

      final searchResults = await service.searchUsersByEmail('user_test', 'sarah');
      expect(searchResults.first.relationship, UserRelationship.none);
    });
  });
}
