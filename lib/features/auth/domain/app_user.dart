import 'package:cloud_firestore/cloud_firestore.dart';

/// User model stored in Firestore `users` collection.
/// Includes partner link, device status, and location data.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? partnerUid;
  final String? fcmToken;
  final int batteryPercentage;
  final bool gpsEnabled;
  final bool internetConnected;
  final bool isOnline;
  final DateTime? lastSeen;
  final double? latitude;
  final double? longitude;
  final DateTime? locationUpdatedAt;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.partnerUid,
    this.fcmToken,
    this.batteryPercentage = 0,
    this.gpsEnabled = false,
    this.internetConnected = false,
    this.isOnline = false,
    this.lastSeen,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
    required this.createdAt,
  });

  bool get isPaired => partnerUid != null && partnerUid!.isNotEmpty;

  bool get hasLocation => latitude != null && longitude != null;

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      partnerUid: data['partnerUid'] as String?,
      fcmToken: data['fcmToken'] as String?,
      batteryPercentage: (data['batteryPercentage'] as num?)?.toInt() ?? 0,
      gpsEnabled: data['gpsEnabled'] as bool? ?? false,
      internetConnected: data['internetConnected'] as bool? ?? false,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      locationUpdatedAt: (data['locationUpdatedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'partnerUid': partnerUid,
      'fcmToken': fcmToken,
      'batteryPercentage': batteryPercentage,
      'gpsEnabled': gpsEnabled,
      'internetConnected': internetConnected,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : FieldValue.serverTimestamp(),
      'latitude': latitude,
      'longitude': longitude,
      'locationUpdatedAt': locationUpdatedAt != null
          ? Timestamp.fromDate(locationUpdatedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates the initial Firestore document for a new user.
  Map<String, dynamic> toNewUserFirestore() {
    return {
      'name': name,
      'email': email,
      'partnerUid': null,
      'fcmToken': null,
      'batteryPercentage': 0,
      'gpsEnabled': false,
      'internetConnected': false,
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'latitude': null,
      'longitude': null,
      'locationUpdatedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? partnerUid,
    String? fcmToken,
    int? batteryPercentage,
    bool? gpsEnabled,
    bool? internetConnected,
    bool? isOnline,
    DateTime? lastSeen,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      partnerUid: partnerUid ?? this.partnerUid,
      fcmToken: fcmToken ?? this.fcmToken,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
      internetConnected: internetConnected ?? this.internetConnected,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
