/// Firebase collection and field name constants.
/// Centralized to prevent typos and enable easy refactoring.
class FirebaseConstants {
  FirebaseConstants._();

  // Collection names
  static const String usersCollection = 'users';
  static const String alertsCollection = 'alerts';
  static const String settingsCollection = 'settings';
  static const String pairRequestsCollection = 'pairRequests';

  // User document fields
  static const String fieldName = 'name';
  static const String fieldEmail = 'email';
  static const String fieldPartnerUid = 'partnerUid';
  static const String fieldFcmToken = 'fcmToken';
  static const String fieldBatteryPercentage = 'batteryPercentage';
  static const String fieldGpsEnabled = 'gpsEnabled';
  static const String fieldInternetConnected = 'internetConnected';
  static const String fieldIsOnline = 'isOnline';
  static const String fieldLastSeen = 'lastSeen';
  static const String fieldLatitude = 'latitude';
  static const String fieldLongitude = 'longitude';
  static const String fieldLocationUpdatedAt = 'locationUpdatedAt';
  static const String fieldCreatedAt = 'createdAt';

  // Alert document fields
  static const String fieldSenderUid = 'senderUid';
  static const String fieldReceiverUid = 'receiverUid';
  static const String fieldAlertType = 'alertType';
  static const String fieldStatus = 'status';
  static const String fieldIsArchived = 'isArchived';
  static const String fieldDeliveredAt = 'deliveredAt';
  static const String fieldSeenAt = 'seenAt';
  static const String fieldAcknowledgedAt = 'acknowledgedAt';
  static const String fieldArchivedAt = 'archivedAt';

  // Settings document fields
  static const String fieldRedSoundEnabled = 'redSoundEnabled';
  static const String fieldGreenSoundEnabled = 'greenSoundEnabled';
  static const String fieldBlueSoundEnabled = 'blueSoundEnabled';
  static const String fieldYellowSoundEnabled = 'yellowSoundEnabled';

  // Pair request fields
  static const String fieldFromUid = 'fromUid';
  static const String fieldFromName = 'fromName';
  static const String fieldFromEmail = 'fromEmail';
  static const String fieldToUid = 'toUid';
  static const String fieldToEmail = 'toEmail';
  static const String fieldRequestStatus = 'status';
}
