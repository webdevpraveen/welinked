import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:welinked/core/constants/alert_constants.dart';

/// Alert model with 4-state lifecycle + isArchived flag.
/// Stored in Firestore `alerts` collection. Never deleted.
class AlertModel {
  final String alertId;
  final String senderUid;
  final String receiverUid;
  final AlertType alertType;
  final AlertStatus status;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? seenAt;
  final DateTime? acknowledgedAt;
  final DateTime? archivedAt;

  const AlertModel({
    required this.alertId,
    required this.senderUid,
    required this.receiverUid,
    required this.alertType,
    required this.status,
    this.isArchived = false,
    required this.createdAt,
    this.deliveredAt,
    this.seenAt,
    this.acknowledgedAt,
    this.archivedAt,
  });

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlertModel(
      alertId: doc.id,
      senderUid: data['senderUid'] as String? ?? '',
      receiverUid: data['receiverUid'] as String? ?? '',
      alertType: AlertType.fromString(data['alertType'] as String? ?? 'red'),
      status: AlertStatus.fromString(data['status'] as String? ?? 'created'),
      isArchived: data['isArchived'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      seenAt: (data['seenAt'] as Timestamp?)?.toDate(),
      acknowledgedAt: (data['acknowledgedAt'] as Timestamp?)?.toDate(),
      archivedAt: (data['archivedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'alertType': alertType.name,
      'status': status.name,
      'isArchived': isArchived,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'seenAt': seenAt != null ? Timestamp.fromDate(seenAt!) : null,
      'acknowledgedAt': acknowledgedAt != null ? Timestamp.fromDate(acknowledgedAt!) : null,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
    };
  }

  AlertModel copyWith({
    String? alertId,
    String? senderUid,
    String? receiverUid,
    AlertType? alertType,
    AlertStatus? status,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? deliveredAt,
    DateTime? seenAt,
    DateTime? acknowledgedAt,
    DateTime? archivedAt,
  }) {
    return AlertModel(
      alertId: alertId ?? this.alertId,
      senderUid: senderUid ?? this.senderUid,
      receiverUid: receiverUid ?? this.receiverUid,
      alertType: alertType ?? this.alertType,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      seenAt: seenAt ?? this.seenAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
