// data/models/property_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_model.dart';

enum PropertyStatus {
  vacant,
  occupied,
  maintenance,
  marketing,
  paid,
}

extension PropertyStatusExtension on PropertyStatus {
  String get value {
    switch (this) {
      case PropertyStatus.vacant:
        return 'vacant';
      case PropertyStatus.occupied:
        return 'occupied';
      case PropertyStatus.maintenance:
        return 'maintenance';
      case PropertyStatus.marketing:
        return 'marketing';
      case PropertyStatus.paid:
        return 'paid';
    }
  }

  static PropertyStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'vacant':
        return PropertyStatus.vacant;
      case 'occupied':
        return PropertyStatus.occupied;
      case 'maintenance':
        return PropertyStatus.maintenance;
      case 'marketing':
        return PropertyStatus.marketing;
      case 'paid':
        return PropertyStatus.paid;
      default:
        return PropertyStatus.vacant;
    }
  }
}

class PropertyModel {
  final String id;
  final String title;
  final String unitId;
  final String description;
  final AddressModel address;
  final String ownerId;
  final String ownerName;
  final double price;
  final double deposit;
  final int bedrooms;
  final int bathrooms;
  final double squareFeet;
  final List<String> amenities;
  final List<String> images;
  final PropertyStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.unitId,
    required this.address,
    required this.ownerId,
    required this.ownerName,
    required this.price,
    required this.deposit,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFeet,
    required this.amenities,
    required this.images,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Add a getter for isAvailable based on status
  bool get isAvailable => status == PropertyStatus.vacant;

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'address': address.toMap(),
      'ownerId': ownerId,
      'ownerName': ownerName,
      'price': price,
      'deposit': deposit,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFeet': squareFeet,
      'amenities': amenities,
      'images': images,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory PropertyModel.fromMap(String id, Map<String, dynamic> map) {
    // Handle Address mapping (Web uses distinct fields, Mobile uses nested AddressModel)
    AddressModel addressObj;
    if (map['address'] is String) {
      addressObj = AddressModel(
        street: map['address'] as String? ?? '',
        city: map['city'] as String? ?? '',
        state: map['country'] as String? ?? '',
        zipCode: '',
      );
    } else {
      addressObj = AddressModel.fromMap(
        map['address'] as Map<String, dynamic>? ?? {},
      );
    }

    // Handle Size parsing (Web uses string "size", Mobile uses double "squareFeet")
    double sizeDouble = 0.0;
    if (map['size'] is String) {
      sizeDouble = double.tryParse((map['size'] as String).replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    } else {
      sizeDouble = (map['squareFeet'] as num?)?.toDouble() ?? (map['size'] as num?)?.toDouble() ?? 0.0;
    }

    return PropertyModel(
      id: id,
      // Map 'name' (Web) to 'title' (Mobile)
      title: map['name'] as String? ?? map['title'] as String? ?? '',
      unitId: map['unitId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      address: addressObj,
      // Map 'landlordId' (Web) to 'ownerId' (Mobile)
      ownerId: map['landlordId'] as String? ?? map['ownerId'] as String? ?? '',
      // Map 'landlordName' (Web) to 'ownerName' (Mobile)
      ownerName: map['landlordName'] as String? ?? map['ownerName'] as String? ?? '',
      // Map 'rentAmount' (Web) to 'price' (Mobile)
      price: (map['rentAmount'] as num?)?.toDouble() ?? (map['price'] as num?)?.toDouble() ?? 0.0,
      deposit: (map['deposit'] as num?)?.toDouble() ?? 0.0,
      bedrooms: map['bedrooms'] as int? ?? 0,
      bathrooms: map['bathrooms'] as int? ?? 0,
      squareFeet: sizeDouble,
      amenities: List<String>.from(map['amenities'] as List? ?? []),
      images: List<String>.from(map['images'] as List? ?? []),
      // Map 'status' (Web: available) to Enum (Mobile: vacant)
      // 'available' will hit default in fromString which is vacant, so it works.
      status: PropertyStatusExtension.fromString(
        map['status'] as String? ?? 'vacant',
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create from Firestore document snapshot
  factory PropertyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyModel.fromMap(doc.id, data);
  }

  // Copy with method
  PropertyModel copyWith({
    String? id,
    String? title,
    String? unitId,
    String? description,
    AddressModel? address,
    String? ownerId,
    String? ownerName,
    double? price,
    double? deposit,
    int? bedrooms,
    int? bathrooms,
    double? squareFeet,
    List<String>? amenities,
    List<String>? images,
    PropertyStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      unitId: unitId ?? this.unitId,

      description: description ?? this.description,
      address: address ?? this.address,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      price: price ?? this.price,
      deposit: deposit ?? this.deposit,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      squareFeet: squareFeet ?? this.squareFeet,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}