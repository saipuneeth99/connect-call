import '../data/models/app_user.dart';
import '../data/models/call.dart';
import '../data/models/call_participant.dart';
import '../data/models/call_status.dart';

class MockData {
  MockData._();

  static const String currentUserId = 'user_current';

  static final AppUser currentUser = AppUser(
    id: currentUserId,
    name: 'Ratan',
    email: 'demo@connectcall.app',
    isOnline: true,
    lastSeen: DateTime.now(),
  );

  static final List<AppUser> users = [
    AppUser(
      id: 'user_1',
      name: 'Sarah Johnson',
      email: 'sarah@example.com',
      isOnline: true,
      lastSeen: DateTime.now(),
    ),
    AppUser(
      id: 'user_2',
      name: 'John Smith',
      email: 'john@example.com',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    AppUser(
      id: 'user_3',
      name: 'Alex Wilson',
      email: 'alex@example.com',
      isOnline: true,
      lastSeen: DateTime.now(),
    ),
    AppUser(
      id: 'user_4',
      name: 'Priya Sharma',
      email: 'priya@example.com',
      isOnline: true,
      lastSeen: DateTime.now(),
    ),
    AppUser(
      id: 'user_5',
      name: 'David Lee',
      email: 'david@example.com',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppUser(
      id: 'user_6',
      name: 'Emily Chen',
      email: 'emily@example.com',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppUser(
      id: 'user_7',
      name: 'Sarah Williams',
      email: 'sarahw@example.com',
      isOnline: true,
      lastSeen: DateTime.now(),
    ),
    AppUser(
      id: 'user_8',
      name: 'Michael Brown',
      email: 'michael@example.com',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static List<AppUser> get favorites => [users[0], users[2], users[3], users[6]];

  static List<String> get favoriteIds =>
      favorites.map((u) => u.id).toList();

  static final List<Call> callHistory = [
    Call(
      id: 'call_1',
      caller: CallParticipant(
          id: currentUserId, name: currentUser.name),
      receiver: CallParticipant(id: 'user_1', name: 'Sarah Johnson'),
      type: CallType.video,
      status: CallStatus.ended,
      direction: CallDirection.outgoing,
      startedAt: DateTime.now().subtract(const Duration(hours: 2)),
      answeredAt: DateTime.now()
          .subtract(const Duration(hours: 2))
          .add(const Duration(seconds: 8)),
      endedAt: DateTime.now()
          .subtract(const Duration(hours: 2))
          .add(const Duration(minutes: 2, seconds: 35)),
    ),
    Call(
      id: 'call_2',
      caller: CallParticipant(id: 'user_2', name: 'John Smith'),
      receiver: CallParticipant(
          id: currentUserId, name: currentUser.name),
      type: CallType.audio,
      status: CallStatus.missed,
      direction: CallDirection.incoming,
      startedAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    Call(
      id: 'call_3',
      caller: CallParticipant(id: 'user_3', name: 'Alex Wilson'),
      receiver: CallParticipant(
          id: currentUserId, name: currentUser.name),
      type: CallType.audio,
      status: CallStatus.ended,
      direction: CallDirection.incoming,
      startedAt: DateTime.now().subtract(const Duration(days: 1)),
      answeredAt: DateTime.now()
          .subtract(const Duration(days: 1))
          .add(const Duration(seconds: 5)),
      endedAt: DateTime.now()
          .subtract(const Duration(days: 1))
          .add(const Duration(minutes: 5, seconds: 12)),
    ),
    Call(
      id: 'call_4',
      caller: CallParticipant(
          id: currentUserId, name: currentUser.name),
      receiver: CallParticipant(id: 'user_4', name: 'Priya Sharma'),
      type: CallType.video,
      status: CallStatus.ended,
      direction: CallDirection.outgoing,
      startedAt: DateTime.now().subtract(const Duration(days: 2)),
      answeredAt: DateTime.now()
          .subtract(const Duration(days: 2))
          .add(const Duration(seconds: 10)),
      endedAt: DateTime.now()
          .subtract(const Duration(days: 2))
          .add(const Duration(minutes: 15, seconds: 47)),
    ),
    Call(
      id: 'call_5',
      caller: CallParticipant(
          id: currentUserId, name: currentUser.name),
      receiver: CallParticipant(id: 'user_5', name: 'David Lee'),
      type: CallType.audio,
      status: CallStatus.rejected,
      direction: CallDirection.outgoing,
      startedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Call(
      id: 'call_6',
      caller: CallParticipant(id: 'user_1', name: 'Sarah Johnson'),
      receiver: CallParticipant(
          id: currentUserId, name: currentUser.name),
      type: CallType.audio,
      status: CallStatus.ended,
      direction: CallDirection.incoming,
      startedAt: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
      answeredAt: DateTime.now()
          .subtract(const Duration(days: 3, hours: 5))
          .add(const Duration(seconds: 4)),
      endedAt: DateTime.now()
          .subtract(const Duration(days: 3, hours: 5))
          .add(const Duration(minutes: 8, seconds: 22)),
    ),
  ];
}
