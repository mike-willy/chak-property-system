import 'package:cloud_firestore/cloud_firestore.dart';

enum TenantStatus {
  active,
  inactive,
  evicted,
}

extension TenantStatusExtension on TenantStatus {
  String get value {
    switch (this) {
      case TenantStatus.active:
        return 'active';
      case TenantStatus.inactive:
        return 'inactive';
      case TenantStatus.evicted:
        return 'evicted';
    }
  }

  static TenantStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return TenantStatus.active;
      case 'inactive':
        return TenantStatus.inactive;
      case 'evicted':
        return TenantStatus.evicted;
      default:
        return TenantStatus.active;
    }
  }
}

class TenantModel {
  final String id;
  final String userId; // Links to UserModel
  final String unitId;
  final String fullName;
  final String email;
  final String phone;
  final String propertyId;
  final String propertyName;
  final String unitNumber;
  final double rentAmount; // Added rentAmount
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final TenantStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  TenantModel({
    required this.id,
    required this.userId,
    required this.unitId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.propertyId = '',
    this.propertyName = '',
    this.unitNumber = '',
    this.rentAmount = 0.0, // Default to 0.0
    this.leaseStartDate,
    this.leaseEndDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'unitId': unitId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'unitNumber': unitNumber,
      'rentAmount': rentAmount,
      'leaseStartDate': leaseStartDate != null ? Timestamp.fromDate(leaseStartDate!) : null,
      'leaseEndDate': leaseEndDate != null ? Timestamp.fromDate(leaseEndDate!) : null,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory TenantModel.fromMap(String id, Map<String, dynamic> map) {
    return TenantModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      unitId: map['unitId'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      propertyId: map['propertyId'] as String? ?? '',
      propertyName: map['propertyName'] as String? ?? '',
      unitNumber: map['unitNumber'] as String? ?? '',
      rentAmount: (map['rentAmount'] as num?)?.toDouble() ?? 0.0,
      leaseStartDate: (map['leaseStartDate'] as Timestamp?)?.toDate(),
      leaseEndDate: (map['leaseEndDate'] as Timestamp?)?.toDate(),
      status: TenantStatusExtension.fromString(map['status'] as String? ?? 'active'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create from Firestore document snapshot
  factory TenantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TenantModel.fromMap(doc.id, data);
  }

  // Copy with method for immutability
  TenantModel copyWith({
    String? id,
    String? userId,
    String? unitId,
    String? fullName,
    String? email,
    String? phone,
    String? propertyId,
    String? propertyName,
    String? unitNumber,
    double? rentAmount,
    DateTime? leaseStartDate,
    DateTime? leaseEndDate,
    TenantStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TenantModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      unitId: unitId ?? this.unitId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      unitNumber: unitNumber ?? this.unitNumber,
      rentAmount: rentAmount ?? this.rentAmount,
      leaseStartDate: leaseStartDate ?? this.leaseStartDate,
      leaseEndDate: leaseEndDate ?? this.leaseEndDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
