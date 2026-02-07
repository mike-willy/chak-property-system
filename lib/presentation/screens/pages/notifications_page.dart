import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/notification_provider.dart';
import '../../../data/models/notification_model.dart';
import '../../../providers/auth_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        context.read<NotificationProvider>().listenToNotifications(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;

    return Scaffold(
      backgroundColor: const Color(0xFF141725),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141725),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (userId != null)
            TextButton(
              onPressed: () => context.read<NotificationProvider>().markAllAsRead(userId),
              child: const Text('Mark all as read', style: TextStyle(color: Color(0xFF4E95FF), fontSize: 12)),
            ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4D95FF)));
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return _buildNotificationItem(context, provider, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something important happens.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationProvider provider, NotificationModel notification) {
    final timeFormat = DateFormat('MMM d, h:mm a');
    
    // Get icon and color based on type and maintenance status
    IconData iconData = _getNotificationIcon(notification.type);
    Color iconColor = _getNotificationColor(notification.type);
    
    // Override for maintenance if status is available
    if (notification.type == NotificationType.maintenance && notification.status != null) {
      final style = _getMaintenanceStyle(notification.status!);
      iconData = style.icon;
      iconColor = style.color;
    }

    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          provider.markAsRead(notification.id);
        }
        // Navigation logic can be added here
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.transparent : const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead 
              ? Border.all(color: Colors.white.withOpacity(0.05))
              : Border.all(color: iconColor.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeFormat.format(notification.createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.application:
      case NotificationType.approval:
        return Icons.assignment_turned_in_outlined;
      case NotificationType.maintenance:
        return Icons.build_outlined;
      case NotificationType.reminder:
        return Icons.calendar_today_outlined;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.payment:
        return Colors.greenAccent;
      case NotificationType.application:
      case NotificationType.approval:
        return Colors.blueAccent;
      case NotificationType.maintenance:
        return Colors.orangeAccent;
      case NotificationType.reminder:
        return Colors.purpleAccent;
      case NotificationType.message:
        return Colors.pinkAccent;
    }
  }

  _MaintenanceStyle _getMaintenanceStyle(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'pending':
        return _MaintenanceStyle(FontAwesomeIcons.circleExclamation, Colors.orange);
      case 'in-progress':
        return _MaintenanceStyle(FontAwesomeIcons.hammer, Colors.blue);
      case 'completed':
        return _MaintenanceStyle(FontAwesomeIcons.circleCheck, Colors.green);
      case 'on-hold':
        return _MaintenanceStyle(FontAwesomeIcons.circlePause, Colors.purple);
      case 'cancelled':
      case 'canceled':
        return _MaintenanceStyle(FontAwesomeIcons.circleXmark, Colors.grey);
      default:
        return _MaintenanceStyle(FontAwesomeIcons.tools, Colors.orangeAccent);
    }
  }
}

class _MaintenanceStyle {
  final IconData icon;
  final Color color;
  _MaintenanceStyle(this.icon, this.color);
}
