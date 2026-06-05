import 'package:intl/intl.dart';

/// Date and time formatting utilities.
class AppDateUtils {
  AppDateUtils._();

  /// Returns a human-readable relative time string.
  /// "Just now", "2 minutes ago", "1 hour ago", "Yesterday", "Jun 5"
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  /// Formats time as "10:35 PM".
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Formats date and time as "Jun 5, 10:35 PM".
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  /// Formats full date as "June 5, 2026".
  static String formatFullDate(DateTime dateTime) {
    return DateFormat('MMMM d, y').format(dateTime);
  }

  /// Formats timestamp for alert history display.
  /// Today: "10:35 PM", Yesterday: "Yesterday", Older: "Jun 5"
  static String formatAlertTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alertDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (alertDay == today) {
      return formatTime(dateTime);
    } else if (alertDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
