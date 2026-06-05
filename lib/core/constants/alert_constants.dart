import 'package:flutter/material.dart';

/// The four fixed alert types with their visual and audio properties.
enum AlertType {
  red,
  green,
  blue,
  yellow;

  String get title {
    switch (this) {
      case AlertType.red:
        return 'RED ALERT';
      case AlertType.green:
        return 'GREEN ALERT';
      case AlertType.blue:
        return 'BLUE ALERT';
      case AlertType.yellow:
        return 'YELLOW ALERT';
    }
  }

  Color get color {
    switch (this) {
      case AlertType.red:
        return const Color(0xFFE53935);
      case AlertType.green:
        return const Color(0xFF43A047);
      case AlertType.blue:
        return const Color(0xFF1E88E5);
      case AlertType.yellow:
        return const Color(0xFFFDD835);
    }
  }

  Color get darkColor {
    switch (this) {
      case AlertType.red:
        return const Color(0xFFB71C1C);
      case AlertType.green:
        return const Color(0xFF1B5E20);
      case AlertType.blue:
        return const Color(0xFF0D47A1);
      case AlertType.yellow:
        return const Color(0xFFF9A825);
    }
  }

  Color get textColor {
    switch (this) {
      case AlertType.yellow:
        return Colors.black87;
      default:
        return Colors.white;
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.red:
        return Icons.warning_rounded;
      case AlertType.green:
        return Icons.check_circle_rounded;
      case AlertType.blue:
        return Icons.info_rounded;
      case AlertType.yellow:
        return Icons.notifications_active_rounded;
    }
  }

  String get audioFile {
    switch (this) {
      case AlertType.red:
        return 'audio/red_alert.mp3';
      case AlertType.green:
        return 'audio/green_alert.mp3';
      case AlertType.blue:
        return 'audio/blue_alert.mp3';
      case AlertType.yellow:
        return 'audio/yellow_alert.mp3';
    }
  }

  static AlertType fromString(String value) {
    return AlertType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertType.red,
    );
  }
}

/// Alert status lifecycle: created → delivered → seen → acknowledged.
/// Archive is separate (isArchived boolean).
enum AlertStatus {
  created,
  delivered,
  seen,
  acknowledged;

  String get displayName {
    switch (this) {
      case AlertStatus.created:
        return 'Created';
      case AlertStatus.delivered:
        return 'Delivered';
      case AlertStatus.seen:
        return 'Seen';
      case AlertStatus.acknowledged:
        return 'Acknowledged';
    }
  }

  Color get badgeColor {
    switch (this) {
      case AlertStatus.created:
        return const Color(0xFF757575);
      case AlertStatus.delivered:
        return const Color(0xFF1E88E5);
      case AlertStatus.seen:
        return const Color(0xFFFFA726);
      case AlertStatus.acknowledged:
        return const Color(0xFF43A047);
    }
  }

  IconData get badgeIcon {
    switch (this) {
      case AlertStatus.created:
        return Icons.schedule;
      case AlertStatus.delivered:
        return Icons.done;
      case AlertStatus.seen:
        return Icons.visibility;
      case AlertStatus.acknowledged:
        return Icons.done_all;
    }
  }

  static AlertStatus fromString(String value) {
    return AlertStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertStatus.created,
    );
  }
}
