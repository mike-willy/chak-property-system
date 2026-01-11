import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  payment,
  application,
  maintenance,
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

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
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
    };
  }

  // Create from Firestore document
  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: NotificationTypeExtension.fromString(
        map['type'] as String? ?? 'payment',
      ),
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create from Firestore document snapshot
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap(doc.id, data);
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
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

