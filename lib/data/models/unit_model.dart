import 'package:cloud_firestore/cloud_firestore.dart';

enum UnitStatus {
  vacant,
  occupied,
  maintenance,
}

extension UnitStatusExtension on UnitStatus {
  String get value {
    switch (this) {
      case UnitStatus.vacant:
        return 'vacant';
      case UnitStatus.occupied:
        return 'occupied';
      case UnitStatus.maintenance:
        return 'maintenance';
    }
  }

  static UnitStatus fromString(String value) {
    switch (value) {
      case 'vacant':
        return UnitStatus.vacant;
      case 'occupied':
        return UnitStatus.occupied;
      case 'maintenance':
        return UnitStatus.maintenance;
      default:
        return UnitStatus.vacant;
    }
  }
}

class UnitModel {
  final String id;
  final String propertyId;
  final String unitNumber;
  final int floor;
  final List<String> features;
  final UnitStatus status;
  final DateTime? availabilityDate;

  UnitModel({
    required this.id,
    required this.propertyId,
    required this.unitNumber,
    required this.floor,
    required this.features,
    required this.status,
    this.availabilityDate,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'unitNumber': unitNumber,
      'floor': floor,
      'features': features,
      'status': status.value,
      if (availabilityDate != null)
        'availabilityDate': Timestamp.fromDate(availabilityDate!),
    };
  }

  // Create from Firestore document
  factory UnitModel.fromMap(String id, Map<String, dynamic> map) {
    return UnitModel(
      id: id,
      propertyId: map['propertyId'] as String? ?? '',
      unitNumber: map['unitNumber'] as String? ?? '',
      floor: map['floor'] as int? ?? 0,
      features: List<String>.from(map['features'] as List? ?? []),
      status: UnitStatusExtension.fromString(
        map['status'] as String? ?? 'vacant',
      ),
      availabilityDate: (map['availabilityDate'] as Timestamp?)?.toDate(),
    );
  }

  // Create from Firestore document snapshot
  factory UnitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UnitModel.fromMap(doc.id, data);
  }

  // Copy with method
  UnitModel copyWith({
    String? id,
    String? propertyId,
    String? unitNumber,
    int? floor,
    List<String>? features,
    UnitStatus? status,
    DateTime? availabilityDate,
  }) {
    return UnitModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitNumber: unitNumber ?? this.unitNumber,
      floor: floor ?? this.floor,
      features: features ?? this.features,
      status: status ?? this.status,
      availabilityDate: availabilityDate ?? this.availabilityDate,
    );
  }
}

