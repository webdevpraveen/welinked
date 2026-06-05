import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/firebase_constants.dart';
import 'package:welinked/features/location/domain/user_location.dart';
import 'package:welinked/shared/providers/firebase_providers.dart';

/// Repository for location data read/write to Firestore.
class LocationRepository {
  final FirebaseFirestore _firestore;

  LocationRepository(this._firestore);

  /// Update the current user's location in Firestore.
  Future<void> updateLocation({
    required String uid,
    required double latitude,
    required double longitude,
  }) async {
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .update({
      'latitude': latitude,
      'longitude': longitude,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream the partner's location from Firestore.
  Stream<UserLocation?> watchPartnerLocation(String partnerUid) {
    return _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(partnerUid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data['latitude'] == null || data['longitude'] == null) {
        return null;
      }
      return UserLocation.fromMap(data);
    });
  }
}

/// Provider for LocationRepository.
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(ref.watch(firestoreProvider));
});
