import 'package:flutter_test/flutter_test.dart';
import 'package:connect_call/data/models/app_user.dart';
import 'package:connect_call/data/models/contact_request.dart';
import 'package:connect_call/data/repositories/contact_repository.dart';
import 'package:connect_call/mock/mock_contact_service.dart';
import 'package:connect_call/modules/contacts/controllers/contacts_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockContactService mockService;
  late ContactRepository repository;
  late ContactsController controller;

  setUp(() {
    mockService = MockContactService();
    repository = ContactRepository(mockService);
    controller = ContactsController(repository);
  });

  tearDown(() {
    controller.dispose();
  });

  test('ContactsController initializes with empty contacts', () async {
    await controller.loadData();
    expect(controller.contacts, isEmpty);
    expect(controller.incomingRequests, isEmpty);
    expect(controller.sentRequests, isEmpty);
  });

  test('ContactsController can search users by registered email', () async {
    final results = await repository.searchUsersByEmail('user_current', 'sarah');
    expect(results, isNotEmpty);
    expect(results.first.user.name, 'Sarah Jenkins');
    expect(results.first.relationship, UserRelationship.none);
  });

  test('ContactsController sendContactRequest adds to sentRequests', () async {
    const targetUser = AppUser(
      id: 'user_1',
      name: 'Sarah Jenkins',
      email: 'sarah.j@example.com',
    );

    controller.searchResults.value = [
      const UserSearchResult(
        user: targetUser,
        relationship: UserRelationship.none,
      ),
    ];

    await controller.sendContactRequest(targetUser);

    expect(controller.sentRequests.length, 1);
    expect(controller.sentRequests.first.receiverId, 'user_1');
    expect(controller.searchResults.first.relationship, UserRelationship.requestSent);
  });

  test('ContactsController acceptContactRequest adds to contacts', () async {
    const sender = AppUser(
      id: 'user_2',
      name: 'David Chen',
      email: 'david.c@example.com',
    );

    final req = ContactRequest(
      id: 'req_123',
      senderId: 'user_2',
      receiverId: 'user_current',
      status: ContactRequestStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sender: sender,
    );

    controller.incomingRequests.value = [req];
    await controller.acceptContactRequest(req);

    expect(controller.incomingRequests, isEmpty);
    expect(controller.contacts.length, 1);
    expect(controller.contacts.first.id, 'user_2');
  });
}
