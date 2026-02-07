import 'package:flutter/material.dart';
import 'dart:async';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository;
  StreamSubscription? _subscription;
  
  NotificationProvider(this._repository);

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get unread count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  String? _listeningUserId;

  /// Listen to notifications in real-time
  void listenToNotifications(String userId) {
    if (_subscription != null && _listeningUserId == userId) return;
    
    // Cancel previous subscription if it exists
    _subscription?.cancel();
    _subscription = null;
    _listeningUserId = userId;
    
    _isLoading = true;
    notifyListeners();

    debugPrint('NotificationProvider: Starting stream for userId: $userId');

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      debugPrint('NotificationProvider: RECEIVED ${snapshot.docs.length} docs for $userId (Source: ${snapshot.metadata.isFromCache ? 'CACHE' : 'SERVER'})');
      
      final list = snapshot.docs.map((doc) {
        try {
          return NotificationModel.fromFirestore(doc);
        } catch (e) {
          debugPrint('NotificationProvider: ERROR parsing doc ${doc.id}: $e');
          return null;
        }
      }).whereType<NotificationModel>().toList();
          
      // Sort in-memory to avoid index requirements
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _notifications = list;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('NotificationProvider: STREAM ERROR for $userId: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Manually re-trigger the listener
  void refreshNotifications() {
    if (_listeningUserId != null) {
      debugPrint('NotificationProvider: Manual refresh requested for $_listeningUserId');
      listenToNotifications(_listeningUserId!);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      // Local state updates automatically via the stream
    } catch (e) {
      _error = 'Failed to update notification: $e';
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final result = await _repository.markAllAsRead(userId);
      result.fold(
        (failure) {
          _error = failure.message;
          notifyListeners();
        },
        (_) {
          // Local state updates automatically via the stream
        },
      );
    } catch (e) {
      _error = 'Failed to mark all as read: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
