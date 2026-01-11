import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaseStatus {
  active,
  expired,
  terminated,
}

extension LeaseStatusExtension on LeaseStatus {
  String get value {
    switch (this) {
      case LeaseStatus.active:
        return 'active';
      case LeaseStatus.expired:
        return 'expired';
      case LeaseStatus.terminated:
        return 'terminated';
    }
  }

  static LeaseStatus fromString(String value) {
    switch (value) {
      case 'active':
        return LeaseStatus.active;
      case 'expired':
        return LeaseStatus.expired;
      case 'terminated':
        return LeaseStatus.terminated;
      default:
        return LeaseStatus.active;
    }
  }
}

class LeaseModel {
  final String id;
  final String tenantId;
  final String unitId;
  final DateTime startDate;
  final DateTime endDate;
  final double rentAmount;
  final int paymentDueDay;
  final double lateFee;
  final LeaseStatus status;
  final String? signedDocument;

  LeaseModel({
    required this.id,
    required this.tenantId,
    required this.unitId,
    required this.startDate,
    required this.endDate,
    required this.rentAmount,
    required this.paymentDueDay,
    required this.lateFee,
    required this.status,
    this.signedDocument,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'unitId': unitId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'rentAmount': rentAmount,
      'paymentDueDay': paymentDueDay,
      'lateFee': lateFee,
      'status': status.value,
      if (signedDocument != null) 'signedDocument': signedDocument,
    };
  }

  // Create from Firestore document
  factory LeaseModel.fromMap(String id, Map<String, dynamic> map) {
    return LeaseModel(
      id: id,
      tenantId: map['tenantId'] as String? ?? '',
      unitId: map['unitId'] as String? ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rentAmount: (map['rentAmount'] as num?)?.toDouble() ?? 0.0,
      paymentDueDay: map['paymentDueDay'] as int? ?? 1,
      lateFee: (map['lateFee'] as num?)?.toDouble() ?? 0.0,
      status: LeaseStatusExtension.fromString(
        map['status'] as String? ?? 'active',
      ),
      signedDocument: map['signedDocument'] as String?,
    );
  }

  // Create from Firestore document snapshot
  factory LeaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaseModel.fromMap(doc.id, data);
  }

  // Check if lease is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return status == LeaseStatus.active &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }

  // Copy with method
  LeaseModel copyWith({
    String? id,
    String? tenantId,
    String? unitId,
    DateTime? startDate,
    DateTime? endDate,
    double? rentAmount,
    int? paymentDueDay,
    double? lateFee,
    LeaseStatus? status,
    String? signedDocument,
  }) {
    return LeaseModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      unitId: unitId ?? this.unitId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rentAmount: rentAmount ?? this.rentAmount,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      lateFee: lateFee ?? this.lateFee,
      status: status ?? this.status,
      signedDocument: signedDocument ?? this.signedDocument,
    );
  }
}

