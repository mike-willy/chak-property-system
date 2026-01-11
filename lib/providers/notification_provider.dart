// providers/notification_provider.dart
import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository;
  
  NotificationProvider(this._repository);

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get unread count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getNotifications(userId);
      result.fold(
        (failure) => _error = failure.message,
        (notifications) => _notifications = notifications,
      );
    } catch (e) {
      _error = 'Failed to load notifications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final result = await _repository.markAsRead(notificationId);
      result.fold(
        (failure) => _error = failure.message,
        (_) {
          // Update local state
          final index = _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(isRead: true);
            notifyListeners();
          }
        },
      );
    } catch (e) {
      _error = 'Failed to update notification: $e';
    }
  }
}
