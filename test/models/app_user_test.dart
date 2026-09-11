import 'package:flutter_test/flutter_test.dart';
import 'package:connect_call/data/models/app_user.dart';

void main() {
  group('AppUser', () {
    test('creates user with required fields', () {
      final user = AppUser(
        id: 'u1',
        name: 'John Smith',
        email: 'john@example.com',
      );

      expect(user.id, 'u1');
      expect(user.name, 'John Smith');
      expect(user.email, 'john@example.com');
      expect(user.isOnline, false);
      expect(user.avatarUrl, isNull);
    });

    test('generates correct initials', () {
      expect(
        AppUser(id: '1', name: 'John Smith', email: 'j@e.com').initials,
        'JS',
      );
      expect(
        AppUser(id: '2', name: 'Sarah', email: 's@e.com').initials,
        'S',
      );
      expect(
        AppUser(id: '3', name: 'Alex B Wilson', email: 'a@e.com').initials,
        'AW',
      );
    });

    test('copyWith creates new instance with updated fields', () {
      final original = AppUser(
        id: 'u1',
        name: 'John Smith',
        email: 'john@example.com',
      );

      final updated = original.copyWith(name: 'John Doe', isOnline: true);

      expect(updated.id, 'u1');
      expect(updated.name, 'John Doe');
      expect(updated.email, 'john@example.com');
      expect(updated.isOnline, true);
    });

    test('equality is based on id', () {
      final user1 = AppUser(id: 'u1', name: 'John', email: 'j@e.com');
      final user2 = AppUser(id: 'u1', name: 'Different', email: 'd@e.com');
      final user3 = AppUser(id: 'u2', name: 'John', email: 'j@e.com');

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('serializes to and from JSON', () {
      final user = AppUser(
        id: 'u1',
        name: 'John Smith',
        email: 'john@example.com',
        isOnline: true,
        lastSeen: DateTime(2024, 1, 1, 12, 0),
      );

      final json = user.toJson();
      final restored = AppUser.fromJson(json);

      expect(restored.id, user.id);
      expect(restored.name, user.name);
      expect(restored.email, user.email);
      expect(restored.isOnline, user.isOnline);
      expect(restored.lastSeen, user.lastSeen);
    });
  });
}
