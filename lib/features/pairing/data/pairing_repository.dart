import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/firebase_constants.dart';
import 'package:welinked/features/pairing/domain/pair_request.dart';
import 'package:welinked/shared/providers/firebase_providers.dart';

/// Repository for the email-based permanent pairing system.
/// No unpair/disconnect functionality — relationship is permanent.
class PairingRepository {
  final FirebaseFirestore _firestore;

  PairingRepository(this._firestore);

  /// Send a partner request by entering their email.
  /// Creates a pair request document in Firestore.
  Future<void> sendPartnerRequest({
    required String fromUid,
    required String fromName,
    required String fromEmail,
    required String toEmail,
  }) async {
    // Check if the target email is registered
    final userQuery = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .where('email', isEqualTo: toEmail.trim())
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('No user found with email: $toEmail');
    }

    final toUid = userQuery.docs.first.id;

    if (toUid == fromUid) {
      throw Exception('You cannot pair with yourself.');
    }

    // Check if already paired
    final currentUser = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(fromUid)
        .get();
    final currentData = currentUser.data();
    if (currentData != null && currentData['partnerUid'] != null) {
      throw Exception('You are already paired with a partner.');
    }

    // Check if the target user is already paired
    final targetData = userQuery.docs.first.data();
    if (targetData['partnerUid'] != null) {
      throw Exception('This user is already paired with someone.');
    }

    // Check if there's already a pending request between these users
    final existingRequest = await _firestore
        .collection(FirebaseConstants.pairRequestsCollection)
        .where('fromUid', isEqualTo: fromUid)
        .where('toEmail', isEqualTo: toEmail.trim())
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception('You already have a pending request to this user.');
    }

    // Create the pair request
    await _firestore
        .collection(FirebaseConstants.pairRequestsCollection)
        .add({
      'fromUid': fromUid,
      'fromName': fromName,
      'fromEmail': fromEmail,
      'toEmail': toEmail.trim(),
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Accept a partner request.
  /// Updates both user documents with permanent partnerUid.
  Future<void> acceptPartnerRequest(PairRequest request) async {
    final batch = _firestore.batch();

    // Update pair request status
    batch.update(
      _firestore
          .collection(FirebaseConstants.pairRequestsCollection)
          .doc(request.id),
      {'status': 'accepted'},
    );

    // Set partnerUid on both users — permanent link
    batch.update(
      _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(request.fromUid),
      {'partnerUid': request.toUid},
    );

    batch.update(
      _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(request.toUid!),
      {'partnerUid': request.fromUid},
    );

    await batch.commit();
  }

  /// Stream of incoming pending pair requests for a user.
  Stream<List<PairRequest>> watchIncomingRequests(String uid) {
    return _firestore
        .collection(FirebaseConstants.pairRequestsCollection)
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PairRequest.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream of outgoing pending pair requests from a user.
  Stream<List<PairRequest>> watchOutgoingRequests(String uid) {
    return _firestore
        .collection(FirebaseConstants.pairRequestsCollection)
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PairRequest.fromFirestore(doc))
          .toList();
    });
  }

  /// Check if the user already has a partner (for reinstall recovery).
  Future<String?> getExistingPartnerUid(String uid) async {
    final doc = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return doc.data()?['partnerUid'] as String?;
  }

  /// Get partner's user document.
  Future<Map<String, dynamic>?> getPartnerData(String partnerUid) async {
    final doc = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(partnerUid)
        .get();
    if (!doc.exists) return null;
    return doc.data();
  }
}

/// Provider for PairingRepository.
final pairingRepositoryProvider = Provider<PairingRepository>((ref) {
  return PairingRepository(ref.watch(firestoreProvider));
});
