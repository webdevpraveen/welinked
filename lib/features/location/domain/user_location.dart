import 'package:cloud_firestore/cloud_firestore.dart';

/// Location data for a user, stored in the user's Firestore document.
class UserLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory UserLocation.fromMap(Map<String, dynamic> data) {
    return UserLocation(
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['locationUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
