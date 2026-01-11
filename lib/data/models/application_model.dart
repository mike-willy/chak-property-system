import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus {
  pending,
  approved,
  rejected,
}

extension ApplicationStatusExtension on ApplicationStatus {
  String get value {
    switch (this) {
      case ApplicationStatus.pending:
        return 'pending';
      case ApplicationStatus.approved:
        return 'approved';
      case ApplicationStatus.rejected:
        return 'rejected';
    }
  }

  static ApplicationStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'approved':
        return ApplicationStatus.approved;
      case 'rejected':
        return ApplicationStatus.rejected;
      default:
        return ApplicationStatus.pending;
    }
  }
}

class ApplicationModel {
  final String id;
  final String tenantId;
  final String unitId;
  final ApplicationStatus status;
  final List<String> documents;
  final DateTime appliedDate;
  final DateTime? decisionDate;
  final String? notes;

  ApplicationModel({
    required this.id,
    required this.tenantId,
    required this.unitId,
    required this.status,
    required this.documents,
    required this.appliedDate,
    this.decisionDate,
    this.notes,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'unitId': unitId,
      'status': status.value,
      'documents': documents,
      'appliedDate': Timestamp.fromDate(appliedDate),
      if (decisionDate != null)
        'decisionDate': Timestamp.fromDate(decisionDate!),
      if (notes != null) 'notes': notes,
    };
  }

  // Create from Firestore document
  factory ApplicationModel.fromMap(String id, Map<String, dynamic> map) {
    return ApplicationModel(
      id: id,
      tenantId: map['tenantId'] as String? ?? '',
      unitId: map['unitId'] as String? ?? '',
      status: ApplicationStatusExtension.fromString(
        map['status'] as String? ?? 'pending',
      ),
      documents: List<String>.from(map['documents'] as List? ?? []),
      appliedDate: (map['appliedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      decisionDate: (map['decisionDate'] as Timestamp?)?.toDate(),
      notes: map['notes'] as String?,
    );
  }

  // Create from Firestore document snapshot
  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApplicationModel.fromMap(doc.id, data);
  }

  // Copy with method
  ApplicationModel copyWith({
    String? id,
    String? tenantId,
    String? unitId,
    ApplicationStatus? status,
    List<String>? documents,
    DateTime? appliedDate,
    DateTime? decisionDate,
    String? notes,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      unitId: unitId ?? this.unitId,
      status: status ?? this.status,
      documents: documents ?? this.documents,
      appliedDate: appliedDate ?? this.appliedDate,
      decisionDate: decisionDate ?? this.decisionDate,
      notes: notes ?? this.notes,
    );
  }
}

