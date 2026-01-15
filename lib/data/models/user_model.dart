import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  tenant,
  landlord,
  admin,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.tenant:
        return 'tenant';
      case UserRole.landlord:
        return 'landlord';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'tenant':
        return UserRole.tenant;
      case 'landlord':
        return UserRole.landlord;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.tenant;
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final DateTime createdAt;
  final bool isVerified;
  final String idNumber;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    required this.createdAt,
    required this.isVerified,
    this.idNumber = '',
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'profileImage': profileImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
      'idNumber': idNumber,
    };
  }

  // Create from Firestore document
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRoleExtension.fromString(map['role'] as String? ?? 'tenant'),
      profileImage: map['profileImage'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: map['isVerified'] as bool? ?? false,
      idNumber: map['idNumber'] as String? ?? '',
    );
  }

  // Create from Firestore document snapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(doc.id, data);
  }

  // Copy with method for immutability
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? profileImage,
    DateTime? createdAt,
    bool? isVerified,
    String? idNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      idNumber: idNumber ?? this.idNumber,
    );
  }
}

