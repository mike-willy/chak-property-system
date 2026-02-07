import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_model.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a notification and saves it to Firestore
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? status,
  }) async {
    try {
      final notification = {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.value,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'status': status,
      };

      final docRef = await _firestore.collection('notifications').add(notification);
      print('NotificationService: Created document with ID: ${docRef.id} for user: $userId');
    } catch (e, stack) {
      print('NotificationService: ERROR creating notification: $e');
      print(stack);
    }
  }

  /// Specialized method for maintenance notifications
  static Future<void> sendMaintenanceNotification({
    required String userId,
    required String propertyName,
    required String status,
  }) async {
    // Format status for display (replace hyphens with spaces)
    final displayStatus = status.toLowerCase().replaceAll('-', ' ');
    
    await createNotification(
      userId: userId,
      title: 'Maintenance Update',
      body: 'Your request for $propertyName is now $displayStatus.',
      type: NotificationType.maintenance,
      status: status, // Store status for dynamic icons
    );
  }

  static Future<void> sendMaintenanceAlert({
    required String userId,
    required String tenantName,
    required String propertyName,
    required String issue,
  }) async {
    await createNotification(
      userId: userId,
      title: 'New Maintenance Request',
      body: '$tenantName submitted a request for $propertyName: $issue',
      type: NotificationType.maintenance,
      status: 'open', // New requests are always 'open'
    );
  }

  /// Specialized method for application approval/rejection
  static Future<void> sendApplicationNotification({
    required String userId,
    required String propertyName,
    required String status,
  }) async {
    final isApproved = status.toLowerCase() == 'approved';
    await createNotification(
      userId: userId,
      title: isApproved ? 'Application Approved!' : 'Application Update',
      body: isApproved 
        ? 'Congratulations! Your application for $propertyName has been approved.'
        : 'Your application for $propertyName was $status.',
      type: isApproved ? NotificationType.approval : NotificationType.application,
    );
  }

  /// Specialized method for new messages
  static Future<void> sendMessageNotification({
    required String userId,
    required String senderName,
    required String messageSnippet,
  }) async {
    await createNotification(
      userId: userId,
      title: 'New Message from $senderName',
      body: messageSnippet.length > 50 
          ? '${messageSnippet.substring(0, 47)}...' 
          : messageSnippet,
      type: NotificationType.message,
    );
  }

  static Future<void> sendRentReminder({
    required String userId,
    required String propertyName,
    required double amount,
  }) async {
    // Check if a reminder for this property was already sent this month
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    final existing = await _firestore.collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: NotificationType.reminder.value)
        .where('title', isEqualTo: 'Rent Reminder')
        .where('createdAt', isGreaterThanOrEqualTo: monthStart)
        .get();

    // If we've already sent a reminder for this property this month, skip
    if (existing.docs.any((doc) => doc.data()['body'].contains(propertyName))) {
      return;
    }

    await createNotification(
      userId: userId,
      title: 'Rent Reminder',
      body: 'Friendly reminder: Rent of KES $amount for $propertyName is due soon.',
      type: NotificationType.reminder,
    );
  }

  static Future<void> sendPaymentNotification({
    required String userId,
    required String propertyName,
    required double amount,
    required String paymentType,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Payment Successful',
      body: 'Your $paymentType payment of KES $amount for $propertyName has been received.',
      type: NotificationType.payment,
    );
  }
}