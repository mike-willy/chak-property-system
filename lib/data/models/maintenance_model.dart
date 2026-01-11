import 'package:cloud_firestore/cloud_firestore.dart';

enum MaintenancePriority {
  low,
  medium,
  high,
}

enum MaintenanceStatus {
  open,
  inProgress,
  completed,
}

extension MaintenancePriorityExtension on MaintenancePriority {
  String get value {
    switch (this) {
      case MaintenancePriority.low:
        return 'low';
      case MaintenancePriority.medium:
        return 'medium';
      case MaintenancePriority.high:
        return 'high';
    }
  }

  static MaintenancePriority fromString(String value) {
    switch (value) {
      case 'low':
        return MaintenancePriority.low;
      case 'medium':
        return MaintenancePriority.medium;
      case 'high':
        return MaintenancePriority.high;
      default:
        return MaintenancePriority.medium;
    }
  }
}

extension MaintenanceStatusExtension on MaintenanceStatus {
  String get value {
    switch (this) {
      case MaintenanceStatus.open:
        return 'open';
      case MaintenanceStatus.inProgress:
        return 'in-progress';
      case MaintenanceStatus.completed:
        return 'completed';
    }
  }

  static MaintenanceStatus fromString(String value) {
    switch (value) {
      case 'open':
        return MaintenanceStatus.open;
      case 'in-progress':
        return MaintenanceStatus.inProgress;
      case 'completed':
        return MaintenanceStatus.completed;
      default:
        return MaintenanceStatus.open;
    }
  }
}

class MaintenanceModel {
  final String id;
  final String tenantId;
  final String unitId;
  final String title;
  final String description;
  final MaintenancePriority priority;
  final MaintenanceStatus status;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceModel({
    required this.id,
    required this.tenantId,
    required this.unitId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'unitId': unitId,
      'title': title,
      'description': description,
      'priority': priority.value,
      'status': status.value,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory MaintenanceModel.fromMap(String id, Map<String, dynamic> map) {
    return MaintenanceModel(
      id: id,
      tenantId: map['tenantId'] as String? ?? '',
      unitId: map['unitId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priority: MaintenancePriorityExtension.fromString(
        map['priority'] as String? ?? 'medium',
      ),
      status: MaintenanceStatusExtension.fromString(
        map['status'] as String? ?? 'open',
      ),
      images: List<String>.from(map['images'] as List? ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create from Firestore document snapshot
  factory MaintenanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaintenanceModel.fromMap(doc.id, data);
  }

  // Copy with method
  MaintenanceModel copyWith({
    String? id,
    String? tenantId,
    String? unitId,
    String? title,
    String? description,
    MaintenancePriority? priority,
    MaintenanceStatus? status,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      unitId: unitId ?? this.unitId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

