import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/firebase_constants.dart';
import 'package:welinked/features/settings/domain/alert_settings.dart';
import 'package:welinked/shared/providers/firebase_providers.dart';

/// Repository for setting values (toggles for alert audio per color).
class SettingsRepository {
  final FirebaseFirestore _firestore;

  SettingsRepository(this._firestore);

  /// Streams user settings from Firestore.
  Stream<AlertSettings> watchSettings(String uid) {
    return _firestore
        .collection(FirebaseConstants.settingsCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return AlertSettings.defaults();
      }
      return AlertSettings.fromMap(doc.data()!);
    });
  }

  /// Updates settings document for a user.
  Future<void> updateSettings(String uid, AlertSettings settings) async {
    await _firestore
        .collection(FirebaseConstants.settingsCollection)
        .doc(uid)
        .set(settings.toMap(), SetOptions(merge: true));
  }
}

/// Settings Repository provider.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(firestoreProvider));
});
