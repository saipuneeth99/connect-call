import 'call_participant.dart';
import 'call_status.dart';

class Call {
  final String id;
  final CallParticipant caller;
  final CallParticipant receiver;
  final CallType type;
  final CallStatus status;
  final CallDirection direction;
  final DateTime startedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;

  const Call({
    required this.id,
    required this.caller,
    required this.receiver,
    required this.type,
    required this.status,
    required this.direction,
    required this.startedAt,
    this.answeredAt,
    this.endedAt,
  });

  Duration? get duration {
    if (answeredAt == null) return null;
    final end = endedAt ?? DateTime.now();
    return end.difference(answeredAt!);
  }

  bool get isMissed => status == CallStatus.missed;
  bool get isRejected => status == CallStatus.rejected;
  bool get isIncoming => direction == CallDirection.incoming;
  bool get isOutgoing => direction == CallDirection.outgoing;
  bool get isVideo => type == CallType.video;
  bool get isAudio => type == CallType.audio;

  CallParticipant get otherParticipant =>
      direction == CallDirection.outgoing ? receiver : caller;

  Call copyWith({
    String? id,
    CallParticipant? caller,
    CallParticipant? receiver,
    CallType? type,
    CallStatus? status,
    CallDirection? direction,
    DateTime? startedAt,
    DateTime? answeredAt,
    DateTime? endedAt,
  }) {
    return Call(
      id: id ?? this.id,
      caller: caller ?? this.caller,
      receiver: receiver ?? this.receiver,
      type: type ?? this.type,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      startedAt: startedAt ?? this.startedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caller': caller.toJson(),
      'receiver': receiver.toJson(),
      'type': type.name,
      'status': status.name,
      'direction': direction.name,
      'started_at': startedAt.toIso8601String(),
      'answered_at': answeredAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'] as String,
      caller: CallParticipant.fromJson(json['caller'] as Map<String, dynamic>),
      receiver:
          CallParticipant.fromJson(json['receiver'] as Map<String, dynamic>),
      type: CallType.values.byName(json['type'] as String),
      status: CallStatus.values.byName(json['status'] as String),
      direction: CallDirection.values.byName(json['direction'] as String),
      startedAt: DateTime.parse(json['started_at'] as String),
      answeredAt: json['answered_at'] != null
          ? DateTime.parse(json['answered_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Call && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Call(id: $id, type: ${type.name}, status: ${status.name}, direction: ${direction.name})';
}
