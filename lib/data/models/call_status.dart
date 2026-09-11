enum CallType {
  audio,
  video;

  String get label {
    switch (this) {
      case CallType.audio:
        return 'Audio Call';
      case CallType.video:
        return 'Video Call';
    }
  }
}

enum CallStatus {
  idle,
  calling,
  ringing,
  connecting,
  connected,
  ended,
  rejected,
  missed,
  busy,
  failed,
  disconnected,
  reconnecting;

  bool get isActive =>
      this == CallStatus.calling ||
      this == CallStatus.ringing ||
      this == CallStatus.connecting ||
      this == CallStatus.connected ||
      this == CallStatus.reconnecting;

  bool get isTerminal =>
      this == CallStatus.ended ||
      this == CallStatus.rejected ||
      this == CallStatus.missed ||
      this == CallStatus.failed;

  String get label {
    switch (this) {
      case CallStatus.idle:
        return '';
      case CallStatus.calling:
        return 'Calling...';
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Call Ended';
      case CallStatus.rejected:
        return 'Call Declined';
      case CallStatus.missed:
        return 'Missed Call';
      case CallStatus.busy:
        return 'Busy';
      case CallStatus.failed:
        return 'Call Failed';
      case CallStatus.disconnected:
        return 'Disconnected';
      case CallStatus.reconnecting:
        return 'Reconnecting...';
    }
  }
}

enum CallDirection {
  incoming,
  outgoing;

  String get label {
    switch (this) {
      case CallDirection.incoming:
        return 'Incoming';
      case CallDirection.outgoing:
        return 'Outgoing';
    }
  }
}
