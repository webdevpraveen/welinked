import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/firebase_constants.dart';
import 'package:welinked/features/auth/domain/app_user.dart';
import 'package:welinked/shared/providers/firebase_providers.dart';

/// Repository for device status read/write.
/// Writes own device status, streams partner's status.
class StatusRepository {
  final FirebaseFirestore _firestore;

  StatusRepository(this._firestore);

  /// Update current user's device status in Firestore.
  Future<void> updateDeviceStatus({
    required String uid,
    required int batteryPercentage,
    required bool gpsEnabled,
    required bool internetConnected,
  }) async {
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .update({
          'batteryPercentage': batteryPercentage,
          'gpsEnabled': gpsEnabled,
          'internetConnected': internetConnected,
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
  }

  /// Update heartbeat (online status + last seen).
  Future<void> updateHeartbeat(String uid) async {
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .update({'isOnline': true, 'lastSeen': FieldValue.serverTimestamp()});
  }

  /// Mark user as offline.
  Future<void> markOffline(String uid) async {
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .update({'isOnline': false, 'lastSeen': FieldValue.serverTimestamp()});
  }

  /// Stream the partner's full user document (includes status, location, etc.).
  Stream<AppUser?> watchPartner(String partnerUid) {
    return _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(partnerUid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return AppUser.fromFirestore(doc);
        });
  }
}

/// Provider for StatusRepository.
final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  return StatusRepository(ref.watch(firestoreProvider));
});
