/// Application-wide constants for intervals, timeouts, and thresholds.
class AppConstants {
  AppConstants._();

  // Alert behavior
  static const int alertPopupDurationSeconds = 10;
  static const int alertCooldownSeconds = 5;

  // Background service intervals (in seconds)
  static const int locationSyncIntervalSeconds = 300; // 5 minutes
  static const int statusSyncIntervalSeconds = 60; // 1 minute
  static const int heartbeatIntervalSeconds = 60; // 1 minute

  // Location thresholds
  static const double locationMovementThresholdMeters = 50.0;

  // Notification channel IDs
  static const String alertChannelId = 'welinked_alerts_v2';
  static const String alertChannelName = 'WeLinked Alerts';
  static const String alertChannelDescription =
      'High priority alert notifications from your duo';

  static const String serviceChannelId = 'welinked_service';
  static const String serviceChannelName = 'Background Service';
  static const String serviceChannelDescription =
      'WeLinked background service for location and status updates';

  static const String ackChannelId = 'welinked_ack';
  static const String ackChannelName = 'Acknowledgement Notifications';
  static const String ackChannelDescription =
      'Notifications when your duo acknowledges alerts';

  // App info
  static const String appName = 'WeLinked';
  static const String appVersion = '1.0.0';
}
