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
  final String? propertyId;

  /// State (admin-controlled after submission)
  final ApplicationStatus status;

  /// Optional tenant uploads
  final List<String> documents;

  /// Audit fields
  final DateTime appliedDate;
  final DateTime? decisionDate;

  final String? rejectionReason;
  final String? propertyName;
  final String? unitName;
  final String? unitNumber;
  final double? monthlyRent;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? notes;
  final DateTime? leaseStart;
  final DateTime? leaseEnd;

  const ApplicationModel({
    required this.id,
    required this.tenantId,
    required this.unitId,
    required this.status,
    required this.documents,
    required this.appliedDate,
    this.decisionDate,
    this.rejectionReason,
    this.propertyName,
    this.unitName,
    this.unitNumber,
    this.monthlyRent,
    this.propertyId,
    this.fullName,
    this.email,
    this.phone,
    this.notes,
    this.leaseStart,
    this.leaseEnd,
  });

  // ----------------------------
  // Factory for TENANT submission
  // ----------------------------
  factory ApplicationModel.newApplication({
    required String id,
    required String tenantId,
    required String unitId,
    String? propertyId,
  }) {
    return ApplicationModel(
      id: id,
      tenantId: tenantId,
      unitId: unitId,
      propertyId: propertyId,
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
      'rejectionReason': rejectionReason,
      'propertyName': propertyName,
      'unitName': unitName,
      'unitNumber': unitNumber,
      'monthlyRent': monthlyRent,
      'propertyId': propertyId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'notes': notes,
      'leaseStart': leaseStart != null ? Timestamp.fromDate(leaseStart!) : null,
      'leaseEnd': leaseEnd != null ? Timestamp.fromDate(leaseEnd!) : null,
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
      rejectionReason: map['rejectionReason'] ?? map['notes'],
      propertyName: map['propertyName'],
      unitName: map['unitName'],
      unitNumber: map['unitNumber']?.toString(),
      monthlyRent: (map['monthlyRent'] as num?)?.toDouble(),
      propertyId: map['propertyId'],
      fullName: map['fullName'],
      email: map['email'],
      phone: map['phone'],
      notes: map['notes'],
      leaseStart: (map['leaseStart'] as Timestamp?)?.toDate(),
      leaseEnd: (map['leaseEnd'] as Timestamp?)?.toDate(),
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
  ApplicationModel reject({String? reason}) {
    return copyWith(
      status: ApplicationStatus.rejected,
      decisionDate: DateTime.now(),
      rejectionReason: reason,
    );
  }

  ApplicationModel copyWith({
    ApplicationStatus? status,
    List<String>? documents,
    DateTime? decisionDate,
    String? rejectionReason,
    String? propertyName,
    String? unitName,
    String? unitNumber,
    double? monthlyRent,
    String? propertyId,
    String? fullName,
    String? email,
    String? phone,
    String? notes,
    DateTime? leaseStart,
    DateTime? leaseEnd,
  }) {
    return ApplicationModel(
      id: id,
      tenantId: tenantId,
      unitId: unitId,
      status: status ?? this.status,
      documents: documents ?? this.documents,
      appliedDate: appliedDate,
      decisionDate: decisionDate ?? this.decisionDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      propertyName: propertyName ?? this.propertyName,
      unitName: unitName ?? this.unitName,
      unitNumber: unitNumber ?? this.unitNumber,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      propertyId: propertyId ?? this.propertyId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      leaseStart: leaseStart ?? this.leaseStart,
      leaseEnd: leaseEnd ?? this.leaseEnd,
    );
  }
}