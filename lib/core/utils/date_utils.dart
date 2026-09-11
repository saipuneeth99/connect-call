import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy · h:mm a').format(dateTime);
  }

  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (_isYesterday(dateTime, now)) {
      return 'Yesterday, ${formatTime(dateTime)}';
    } else if (diff.inDays < 7) {
      return '${DateFormat('EEEE').format(dateTime)}, ${formatTime(dateTime)}';
    } else {
      return formatDate(dateTime);
    }
  }

  static String formatCallTimestamp(DateTime dateTime) {
    final now = DateTime.now();

    if (_isToday(dateTime, now)) {
      return 'Today, ${formatTime(dateTime)}';
    } else if (_isYesterday(dateTime, now)) {
      return 'Yesterday, ${formatTime(dateTime)}';
    } else {
      return '${DateFormat('MMM d').format(dateTime)}, ${formatTime(dateTime)}';
    }
  }

  static String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inMinutes < 1) {
      return 'Last seen just now';
    } else if (diff.inMinutes < 60) {
      return 'Last seen ${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return 'Last seen ${diff.inHours}h ago';
    } else {
      return 'Last seen ${formatRelative(lastSeen)}';
    }
  }

  static String formatGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static bool _isToday(DateTime date, DateTime now) {
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool _isYesterday(DateTime date, DateTime now) {
    final yesterday = now.subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}
