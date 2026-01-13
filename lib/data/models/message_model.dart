// lib/data/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String? id;
  final String recipientId;
  final String recipientType;
  final String recipientName;
  final String recipientEmail;
  final String recipientPhone;
  final String subject;
  final String message;
  final String sender;
  final String senderId;
  final String status;
  final Timestamp createdAt;
  final bool read;
  final Timestamp? receivedAt;
  final String? messageId;

  Message({
    this.id,
    required this.recipientId,
    required this.recipientType,
    required this.recipientName,
    required this.recipientEmail,
    required this.recipientPhone,
    required this.subject,
    required this.message,
    required this.sender,
    required this.senderId,
    required this.status,
    required this.createdAt,
    required this.read,
    this.receivedAt,
    this.messageId,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      recipientType: data['recipientType'] ?? '',
      recipientName: data['recipientName'] ?? '',
      recipientEmail: data['recipientEmail'] ?? '',
      recipientPhone: data['recipientPhone'] ?? '',
      subject: data['subject'] ?? 'No Subject',
      message: data['message'] ?? '',
      sender: data['sender'] ?? '',
      senderId: data['senderId'] ?? '',
      status: data['status'] ?? 'sent',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      read: data['read'] ?? false,
      receivedAt: data['receivedAt'],
      messageId: data['messageId'],
    );
  }

  factory Message.fromMap(Map<String, dynamic> data, {String? id}) {
    return Message(
      id: id,
      recipientId: data['recipientId'] ?? '',
      recipientType: data['recipientType'] ?? '',
      recipientName: data['recipientName'] ?? '',
      recipientEmail: data['recipientEmail'] ?? '',
      recipientPhone: data['recipientPhone'] ?? '',
      subject: data['subject'] ?? 'No Subject',
      message: data['message'] ?? '',
      sender: data['sender'] ?? '',
      senderId: data['senderId'] ?? '',
      status: data['status'] ?? 'sent',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      read: data['read'] ?? false,
      receivedAt: data['receivedAt'],
      messageId: data['messageId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'recipientType': recipientType,
      'recipientName': recipientName,
      'recipientEmail': recipientEmail,
      'recipientPhone': recipientPhone,
      'subject': subject,
      'message': message,
      'sender': sender,
      'senderId': senderId,
      'status': status,
      'createdAt': createdAt,
      'read': read,
      if (receivedAt != null) 'receivedAt': receivedAt,
      if (messageId != null) 'messageId': messageId,
    };
  }

  Message copyWith({
    String? id,
    String? recipientId,
    String? recipientType,
    String? recipientName,
    String? recipientEmail,
    String? recipientPhone,
    String? subject,
    String? message,
    String? sender,
    String? senderId,
    String? status,
    Timestamp? createdAt,
    bool? read,
    Timestamp? receivedAt,
    String? messageId,
  }) {
    return Message(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      recipientType: recipientType ?? this.recipientType,
      recipientName: recipientName ?? this.recipientName,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      sender: sender ?? this.sender,
      senderId: senderId ?? this.senderId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      receivedAt: receivedAt ?? this.receivedAt,
      messageId: messageId ?? this.messageId,
    );
  }
}