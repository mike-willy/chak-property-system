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
  onHold,
  canceled,
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
        return 'pending'; // Changed from 'open'
      case MaintenanceStatus.inProgress:
        return 'in-progress';
      case MaintenanceStatus.completed:
        return 'completed';
      case MaintenanceStatus.onHold:
        return 'on-hold'; // Changed from 'on hold'
      case MaintenanceStatus.canceled:
        return 'cancelled'; // Changed from 'request canceled'
    }
  }

  static MaintenanceStatus fromString(String value) {
    switch (value) {
      case 'pending': // Changed from 'open'
      case 'open': // Keep for backward compatibility
        return MaintenanceStatus.open;
      case 'in-progress':
        return MaintenanceStatus.inProgress;
      case 'completed':
        return MaintenanceStatus.completed;
      case 'on-hold': // Changed from 'on hold'
      case 'on hold':
        return MaintenanceStatus.onHold;
      case 'cancelled': // Changed from 'request canceled'
      case 'request canceled':
        return MaintenanceStatus.canceled;
      default:
        return MaintenanceStatus.open;
    }
  }
}

class MaintenanceModel {
  final String id;
  final String tenantId;
  final String unitId;  
  final String tenantName;
  final String propertyName;
  final String unitName;
  final String title;
  final String description;
  final MaintenancePriority priority;
  final MaintenanceStatus status;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminNotes; // New field
  final DateTime? completedAt; // New field
  final DateTime? onHoldAt; // New field
  final DateTime? cancelledAt; // New field

  MaintenanceModel({
    required this.id,
    required this.tenantId,
    required this.unitId,
    required this.tenantName,
    required this.propertyName,
    required this.unitName,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.adminNotes,
    this.completedAt,
    this.onHoldAt,
    this.cancelledAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'unitId': unitId,
      'tenantName': tenantName,
      'propertyName': propertyName,
      'unitName': unitName,
      'title': title,
      'description': description,
      'priority': priority.value,
      'status': status.value,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'adminNotes': adminNotes,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'onHoldAt': onHoldAt != null ? Timestamp.fromDate(onHoldAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    };
  }

  // Create from Firestore document
  factory MaintenanceModel.fromMap(String id, Map<String, dynamic> map) {
    return MaintenanceModel(
      id: id,
      tenantId: map['tenantId'] as String? ?? '',
      unitId: map['unitId'] as String? ?? '',
      tenantName: map['tenantName'] as String? ?? '',
      propertyName: map['propertyName'] as String? ?? '',
      unitName: map['unitName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priority: MaintenancePriorityExtension.fromString(
        map['priority'] as String? ?? 'medium',
      ),
      status: MaintenanceStatusExtension.fromString(
        map['status'] as String? ?? 'pending',
      ),
      images: List<String>.from(map['images'] as List? ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminNotes: map['adminNotes'] as String?,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      onHoldAt: (map['onHoldAt'] as Timestamp?)?.toDate(),
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
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
    String? tenantName,
    String? propertyName,
    String? unitName,
    String? title,
    String? description,
    MaintenancePriority? priority,
    MaintenanceStatus? status,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminNotes,
    DateTime? completedAt,
    DateTime? onHoldAt,
    DateTime? cancelledAt,
  }) {
    return MaintenanceModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      unitId: unitId ?? this.unitId,
      tenantName: tenantName ?? this.tenantName,
      propertyName: propertyName ?? this.propertyName,
      unitName: unitName ?? this.unitName,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      completedAt: completedAt ?? this.completedAt,
      onHoldAt: onHoldAt ?? this.onHoldAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}

