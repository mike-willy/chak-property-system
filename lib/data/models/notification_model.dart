import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  payment,
  application,
  maintenance,
  approval,
  reminder,
  message,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.payment:
        return 'payment';
      case NotificationType.application:
        return 'application';
      case NotificationType.maintenance:
        return 'maintenance';
      case NotificationType.approval:
        return 'approval';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.message:
        return 'message';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'payment':
        return NotificationType.payment;
      case 'application':
        return NotificationType.application;
      case 'maintenance':
        return NotificationType.maintenance;
      case 'approval':
        return NotificationType.approval;
      case 'reminder':
        return NotificationType.reminder;
      case 'message':
        return NotificationType.message;
      default:
        return NotificationType.payment;
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? status; // New field for maintenance/application status

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.status,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.value,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  // Create from Firestore document snapshot
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap(map, doc.id);
  }

  // Create from Map
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationTypeExtension.fromString(map['type'] ?? 'payment'),
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String?,
    );
  }

  // Copy with method
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    String? status,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

