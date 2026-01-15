// data/models/maintenance_category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceCategoryModel {
  final String id;
  final String name;
  final String description;
  final String icon;

  MaintenanceCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  factory MaintenanceCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaintenanceCategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
    };
  }
}
