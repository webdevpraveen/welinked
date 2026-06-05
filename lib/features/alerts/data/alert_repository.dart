import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:welinked/core/constants/alert_constants.dart';
import 'package:welinked/core/constants/firebase_constants.dart';
import 'package:welinked/features/alerts/domain/alert_model.dart';
import 'package:welinked/shared/providers/firebase_providers.dart';

/// Repository for alert CRUD operations.
/// Alerts are NEVER deleted — only archived with isArchived = true.
class AlertRepository {
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  AlertRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _alertsRef =>
      _firestore.collection(FirebaseConstants.alertsCollection);

  /// Create a new alert. Status = created.
  Future<String> createAlert({
    required String senderUid,
    required String receiverUid,
    required AlertType alertType,
  }) async {
    final alertId = _uuid.v4();
    final alert = AlertModel(
      alertId: alertId,
      senderUid: senderUid,
      receiverUid: receiverUid,
      alertType: alertType,
      status: AlertStatus.created,
      isArchived: false,
      createdAt: DateTime.now(),
    );
    await _alertsRef.doc(alertId).set(alert.toFirestore());
    return alertId;
  }

  /// Mark alert as delivered (receiver's device received it).
  Future<void> markDelivered(String alertId) async {
    await _alertsRef.doc(alertId).update({
      'status': AlertStatus.delivered.name,
      'deliveredAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark alert as seen (receiver viewed it in history or notification).
  Future<void> markSeen(String alertId) async {
    await _alertsRef.doc(alertId).update({
      'status': AlertStatus.seen.name,
      'seenAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark alert as acknowledged (receiver pressed OK).
  Future<void> markAcknowledged(String alertId) async {
    await _alertsRef.doc(alertId).update({
      'status': AlertStatus.acknowledged.name,
      'acknowledgedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Archive an alert (swipe action). Never deletes.
  Future<void> archiveAlert(String alertId) async {
    await _alertsRef.doc(alertId).update({
      'isArchived': true,
      'archivedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of non-archived alerts received by a user, newest first.
  Stream<List<AlertModel>> watchReceivedAlerts(String uid) {
    return _alertsRef
        .where('receiverUid', isEqualTo: uid)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AlertModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Stream of non-archived alerts sent by a user, newest first.
  Stream<List<AlertModel>> watchSentAlerts(String uid) {
    return _alertsRef
        .where('senderUid', isEqualTo: uid)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AlertModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Stream of ALL non-archived alerts involving a user (sent + received), newest first.
  /// Used for the alert history screen.
  Stream<List<AlertModel>> watchAllAlerts(String uid) {
    return _alertsRef
        .where('isArchived', isEqualTo: false)
        .where(Filter.or(
          Filter('receiverUid', isEqualTo: uid),
          Filter('senderUid', isEqualTo: uid),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AlertModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get a single alert by ID.
  Future<AlertModel?> getAlert(String alertId) async {
    final doc = await _alertsRef.doc(alertId).get();
    if (!doc.exists) return null;
    return AlertModel.fromFirestore(doc);
  }
}

/// Provider for AlertRepository.
final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(ref.watch(firestoreProvider));
});
