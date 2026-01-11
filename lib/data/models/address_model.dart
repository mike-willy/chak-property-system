import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final GeoPoint? coordinates;

  AddressModel({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.coordinates,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      if (coordinates != null) 'coordinates': coordinates,
    };
  }

  // Create from Firestore map
  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      street: map['street'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      zipCode: map['zipCode'] as String? ?? '',
      coordinates: map['coordinates'] as GeoPoint?,
    );
  }

  // Full address as string
  String get fullAddress => '$street, $city, $state $zipCode';

  // Copy with method
  AddressModel copyWith({
    String? street,
    String? city,
    String? state,
    String? zipCode,
    GeoPoint? coordinates,
  }) {
    return AddressModel(
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}

