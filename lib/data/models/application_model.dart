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
      case 'approved':
        return ApplicationStatus.approved;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'pending':
      default:
        return ApplicationStatus.pending;
    }
  }
}

class ApplicationModel {
  final String id;

  /// Immutable identity fields (tenant-controlled ONLY at creation)
  final String tenantId;
  final String unitId;

  /// State (admin-controlled after submission)
  final ApplicationStatus status;

  /// Optional tenant uploads
  final List<String> documents;

  /// Audit fields
  final DateTime appliedDate;
  final DateTime? decisionDate;

  /// Admin-only feedback
  final String? notes;

  /// Denormalized fields for display
  final String? propertyName;
  final String? unitName;
  final String? unitNumber;
  final double? monthlyRent;

  const ApplicationModel({
    required this.id,
    required this.tenantId,
    required this.unitId,
    required this.status,
    required this.documents,
    required this.appliedDate,
    this.decisionDate,
    this.notes,
    this.propertyName,
    this.unitName,
    this.unitNumber,
    this.monthlyRent,
  });

  // ----------------------------
  // Factory for TENANT submission
  // ----------------------------
  factory ApplicationModel.newApplication({
    required String id,
    required String tenantId,
    required String unitId,
  }) {
    return ApplicationModel(
      id: id,
      tenantId: tenantId,
      unitId: unitId,
      status: ApplicationStatus.pending,
      documents: const [],
      appliedDate: DateTime.now(),
    );
  }

  // ----------------------------
  // Firestore serialization
  // ----------------------------
  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'unitId': unitId,
      'status': status.value,
      'documents': documents,
      'appliedDate': Timestamp.fromDate(appliedDate),
      'decisionDate':
          decisionDate != null ? Timestamp.fromDate(decisionDate!) : null,
      'notes': notes,
      'propertyName': propertyName,
      'unitName': unitName,
      'unitNumber': unitNumber,
      'monthlyRent': monthlyRent,
    };
  }

  factory ApplicationModel.fromMap(String id, Map<String, dynamic> map) {
    return ApplicationModel(
      id: id,
      tenantId: map['tenantId'] ?? '',
      unitId: map['unitId'] ?? '',
      status: ApplicationStatusExtension.fromString(
        map['status'] ?? 'pending',
      ),
      documents: List<String>.from(map['documents'] ?? []),
      appliedDate:
          (map['appliedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      decisionDate: (map['decisionDate'] as Timestamp?)?.toDate(),
      notes: map['notes'],
      propertyName: map['propertyName'],
      unitName: map['unitName'],
      unitNumber: map['unitNumber']?.toString(), // Handle simplified int storage
      monthlyRent: (map['monthlyRent'] as num?)?.toDouble(),
    );
  }

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApplicationModel.fromMap(doc.id, data);
  }

  // ----------------------------
  // Controlled mutations
  // ----------------------------

  /// Admin approval
  ApplicationModel approve({String? notes}) {
    return copyWith(
      status: ApplicationStatus.approved,
      decisionDate: DateTime.now(),
      notes: notes,
    );
  }

  /// Admin rejection
  ApplicationModel reject({String? notes}) {
    return copyWith(
      status: ApplicationStatus.rejected,
      decisionDate: DateTime.now(),
      notes: notes,
    );
  }

  ApplicationModel copyWith({
    ApplicationStatus? status,
    List<String>? documents,
    DateTime? decisionDate,
    String? notes,
    String? propertyName,
    String? unitName,
    String? unitNumber,
    double? monthlyRent,
  }) {
    return ApplicationModel(
      id: id,
      tenantId: tenantId,
      unitId: unitId,
      status: status ?? this.status,
      documents: documents ?? this.documents,
      appliedDate: appliedDate,
      decisionDate: decisionDate ?? this.decisionDate,
      notes: notes ?? this.notes,
      propertyName: propertyName ?? this.propertyName,
      unitName: unitName ?? this.unitName,
      unitNumber: unitNumber ?? this.unitNumber,
      monthlyRent: monthlyRent ?? this.monthlyRent,
    );
  }
}
