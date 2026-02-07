// lib/providers/message_provider.dart
import 'package:flutter/foundation.dart';
import '../data/repositories/message_repository.dart';
import '../data/models/message_model.dart';
import '../core/services/notification_service.dart' as service;
import '../data/models/notification_model.dart';

class MessageProvider with ChangeNotifier {
  final MessageRepository _messageRepository;
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  MessageProvider({required MessageRepository messageRepository})
      : _messageRepository = messageRepository;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  void initialize(String userId, String userRole) {
    _loadMessages(userId, userRole);
    _loadUnreadCount(userId, userRole);
  }

  Future<void> _loadMessages(String userId, String userRole) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messageRepository.getMessages(userId, userRole).listen((messages) {
        _messages = messages;
        _isLoading = false;
        
        // Update unread count
        _unreadCount = messages.where((msg) => !msg.read).length;
        
        notifyListeners();
      }, onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUnreadCount(String userId, String userRole) async {
    try {
      final count = await _messageRepository.getUnreadCount(userId, userRole);
      _unreadCount = count;
      notifyListeners();
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  Future<void> markAsRead(String messageId, String userId, String userRole) async {
    try {
      await _messageRepository.markAsRead(messageId, userId, userRole);
      
      // Update local state
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(read: true);
        _unreadCount = _messages.where((msg) => !msg.read).length;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendReply(String originalMessageId, String replyMessage) async {
    try {
      await _messageRepository.sendReply(originalMessageId, replyMessage);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendMessageToAdmin(String subject, String message) async {
    try {
      await _messageRepository.sendMessageToAdmin(subject, message);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh(String userId, String userRole) {
    _loadMessages(userId, userRole);
    _loadUnreadCount(userId, userRole);
  }
}