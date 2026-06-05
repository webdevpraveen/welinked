import 'package:cloud_firestore/cloud_firestore.dart';

/// Pair request model for email-based partner pairing.
/// Stored in Firestore `pairRequests` collection.
class PairRequest {
  final String id;
  final String fromUid;
  final String fromName;
  final String fromEmail;
  final String toEmail;
  final String? toUid;
  final String status; // 'pending', 'accepted'
  final DateTime createdAt;

  const PairRequest({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromEmail,
    required this.toEmail,
    this.toUid,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  factory PairRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PairRequest(
      id: doc.id,
      fromUid: data['fromUid'] as String? ?? '',
      fromName: data['fromName'] as String? ?? '',
      fromEmail: data['fromEmail'] as String? ?? '',
      toEmail: data['toEmail'] as String? ?? '',
      toUid: data['toUid'] as String?,
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUid': fromUid,
      'fromName': fromName,
      'fromEmail': fromEmail,
      'toEmail': toEmail,
      'toUid': toUid,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
