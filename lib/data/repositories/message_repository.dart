// lib/data/repositories/message_repository.dart
import 'dart:async';
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class MessageRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MessageRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Stream<List<Message>> getMessages(String userId, String userRole) {
    if (userRole == 'tenant') {
      return _getMessagesForTenant(userId);
    } else if (userRole == 'landlord') {
      return _getMessagesForLandlord(userId);
    }
    return const Stream.empty();
  }

  Stream<List<Message>> _getMessagesForTenant(String userId) {
    try {
      // Stream for received messages (global)
      final globalMessagesStream = _firestore
          .collection('messages')
          .where('recipientId', isEqualTo: userId)
          .where('recipientType', isEqualTo: 'tenant')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());

      // Stream for received messages (subcollection)
      final userMessagesStream = _firestore
          .collection('users')
          .doc(userId)
          .collection('messages')
          .orderBy('receivedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Message.fromMap(doc.data(), id: doc.id))
              .toList());

      // Stream for SENT messages
      final sentMessagesStream = _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());

      return StreamGroup.merge([
        globalMessagesStream,
        userMessagesStream,
        sentMessagesStream,
      ]).asyncMap((messages) async {
        return await _combineTenantMessages(userId);
      });
    } catch (e) {
      print('Error in tenant messages stream: $e');
      return Stream.value([]);
    }
  }

  Future<List<Message>> _combineTenantMessages(String userId) async {
    List<Message> messages = [];

    try {
      // Get received from global collection
      final globalQuery = await _firestore
          .collection('messages')
          .where('recipientId', isEqualTo: userId)
          .where('recipientType', isEqualTo: 'tenant')
          .orderBy('createdAt', descending: true)
          .get();

      messages.addAll(globalQuery.docs.map((doc) => Message.fromFirestore(doc)));

      // Get received from user subcollection
      final userQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('messages')
          .orderBy('receivedAt', descending: true)
          .get();

      messages.addAll(userQuery.docs
          .map((doc) => Message.fromMap(doc.data(), id: doc.id)));

      // Get SENT messages
      final sentQuery = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      messages.addAll(sentQuery.docs.map((doc) => Message.fromFirestore(doc)));

      // Remove duplicates based on messageId or docId
      final seenIds = <String>{};
      final uniqueMessages = messages.where((message) {
        // Use messageId if available (for subcollection messages), otherwise doc ID
        final id = message.messageId ?? message.id;
        if (id != null) {
          if (seenIds.contains(id)) {
            return false;
          }
          seenIds.add(id);
        }
        return true;
      }).toList();

      // Sort by date (newest first)
      uniqueMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return uniqueMessages;
    } catch (e) {
      print('Error combining tenant messages: $e');
      return [];
    }
  }

  Stream<List<Message>> _getMessagesForLandlord(String landlordId) {
    try {
      // Stream for received messages (global)
      final globalMessagesStream = _firestore
          .collection('messages')
          .where('recipientId', isEqualTo: landlordId)
          .where('recipientType', isEqualTo: 'landlord')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());

      // Stream for received messages (landlord subcollection)
      final landlordMessagesStream = _firestore
          .collection('landlords')
          .doc(landlordId)
          .collection('messages')
          .orderBy('receivedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Message.fromMap(doc.data(), id: doc.id))
              .toList());

      // Stream for received messages (users subcollection - fallback/legacy)
      final userMessagesStream = _firestore
          .collection('users')
          .doc(landlordId)
          .collection('messages')
          .orderBy('receivedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Message.fromMap(doc.data(), id: doc.id))
              .toList());

      // Stream for SENT messages
      final sentMessagesStream = _firestore
          .collection('messages')
          .where('senderId', isEqualTo: landlordId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());

      return StreamGroup.merge([
        globalMessagesStream,
        landlordMessagesStream,
        userMessagesStream,
        sentMessagesStream,
      ]).asyncMap((messages) async {
        return await _combineLandlordMessages(landlordId);
      });
    } catch (e) {
      print('Error in landlord messages stream: $e');
      return Stream.value([]);
    }
  }

  Future<List<Message>> _combineLandlordMessages(String landlordId) async {
    List<Message> messages = [];

    try {
      // Get received from global collection
      final globalQuery = await _firestore
          .collection('messages')
          .where('recipientId', isEqualTo: landlordId)
          .where('recipientType', isEqualTo: 'landlord')
          .orderBy('createdAt', descending: true)
          .get();

      messages.addAll(globalQuery.docs.map((doc) => Message.fromFirestore(doc)));

      // Get received from landlord subcollection
      final landlordQuery = await _firestore
          .collection('landlords')
          .doc(landlordId)
          .collection('messages')
          .orderBy('receivedAt', descending: true)
          .get();

      messages.addAll(landlordQuery.docs
          .map((doc) => Message.fromMap(doc.data(), id: doc.id)));

      // Get received from users subcollection (fallback)
      try {
        final userQuery = await _firestore
            .collection('users')
            .doc(landlordId)
            .collection('messages')
            .orderBy('receivedAt', descending: true)
            .get();

        messages.addAll(userQuery.docs
            .map((doc) => Message.fromMap(doc.data(), id: doc.id)));
      } catch (e) {
        // Ignore errors from users subcollection (e.g. if it doesn't exist)
        print('Warning: Failed to fetch messages from users subcollection for landlord: $e');
      }

      // Get SENT messages
      final sentQuery = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: landlordId)
          .orderBy('createdAt', descending: true)
          .get();

      messages.addAll(sentQuery.docs.map((doc) => Message.fromFirestore(doc)));

      // Remove duplicates
      final seenIds = <String>{};
      final uniqueMessages = messages.where((message) {
        final id = message.messageId ?? message.id;
        if (id != null) {
          if (seenIds.contains(id)) {
            return false;
          }
          seenIds.add(id);
        }
        return true;
      }).toList();

      // Sort by date (newest first)
      uniqueMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return uniqueMessages;
    } catch (e) {
      print('Error combining landlord messages: $e');
      return [];
    }
  }

  Future<int> getUnreadCount(String userId, String userRole) async {
    int count = 0;
    try {
      // Count from global messages
      final globalQuery = await _firestore
          .collection('messages')
          .where('recipientId', isEqualTo: userId)
          .where('recipientType', isEqualTo: userRole)
          .where('read', isEqualTo: false)
          .count()
          .get();
      
      count += globalQuery.count ?? 0;

      // Count from subcollection messages
      AggregateQuerySnapshot? subQuery;
      if (userRole == 'tenant') {
        subQuery = await _firestore
            .collection('users')
            .doc(userId)
            .collection('messages')
            .where('read', isEqualTo: false)
            .count()
            .get();
      } else if (userRole == 'landlord') {
        // Check landlords collection
        subQuery = await _firestore
            .collection('landlords')
            .doc(userId)
            .collection('messages')
            .where('read', isEqualTo: false)
            .count()
            .get();
        
        // Also check users collection (fallback)
        final userSubQuery = await _firestore
            .collection('users')
            .doc(userId)
            .collection('messages')
            .where('read', isEqualTo: false)
            .count()
            .get();
        
        if (userSubQuery.count != null) {
          count += userSubQuery.count!;
        }
      }
      
      if (subQuery != null) {
        count += subQuery.count ?? 0;
      }
    } catch (e) {
      print('Error getting unread count: $e');
    }
    return count;
  }

  Future<void> markAsRead(String messageId, String userId, String userRole) async {
    try {
      // We don't know if the message is in the global list or subcollection easily
      // So we'll try to update it in the most likely places or query to find it first.
      
      // Strategy: Try global first, if it fails (doesn't exist), try subcollection.
      // Note: Firestore update() fails if doc doesn't exist.
      
      final globalDoc = _firestore.collection('messages').doc(messageId);
      final globalSnapshot = await globalDoc.get();

      if (globalSnapshot.exists) {
        await globalDoc.update({'read': true});
      } else {
        // Try subcollection
        DocumentReference? subDoc;
        if (userRole == 'tenant') {
          subDoc = _firestore
              .collection('users')
              .doc(userId)
              .collection('messages')
              .doc(messageId);
              
          // Check if exists before updating
          final subSnapshot = await subDoc.get();
          if (subSnapshot.exists) {
            await subDoc.update({'read': true});
          }
        } else if (userRole == 'landlord') {
          // Try landlords collection first
          subDoc = _firestore
              .collection('landlords')
              .doc(userId)
              .collection('messages')
              .doc(messageId);
              
          final subSnapshot = await subDoc.get();
          if (subSnapshot.exists) {
            await subDoc.update({'read': true});
          } else {
            // Try users collection (fallback)
            final userSubDoc = _firestore
                .collection('users')
                .doc(userId)
                .collection('messages')
                .doc(messageId);
                
            final userSubSnapshot = await userSubDoc.get();
            if (userSubSnapshot.exists) {
              await userSubDoc.update({'read': true});
            }
          }
        }
      }
    } catch (e) {
      print('Error marking message as read: $e');
      rethrow;
    }
  }

  Future<void> sendReply(String originalMessageId, String replyMessage) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to send a reply');
    }

    try {
      // 1. Fetch original message to get context (subject, sender to reply to)
      // We'll search for it similarly to markAsRead, assuming it could be anywhere.
      // But for simplicity, we'll assume we can find it or just create a new message to Admin.
      
      // Since the UI says "Reply to Admin", we will default to sending to Admin.
      // Construct the message
      
      final messageData = {
        'recipientId': 'admin', // Flag for admin
        'recipientType': 'admin',
        'recipientName': 'Admin',
        'recipientEmail': 'admin@system.com', // Placeholder
        'recipientPhone': '',
        'subject': 'Reply to message', // We could fetch original subject if we wanted
        'message': replyMessage,
        'sender': user.email ?? user.displayName ?? 'User',
        'senderId': user.uid,
        'status': 'sent',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'originalMessageId': originalMessageId,
      };

      await _firestore.collection('messages').add(messageData);
      
    } catch (e) {
      print('Error sending reply: $e');
      rethrow;
    }
  }

  Future<void> sendMessageToAdmin(String subject, String message) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to send a message');
    }

    try {
      final messageData = {
        'recipientId': 'admin',
        'recipientType': 'admin',
        'recipientName': 'Admin',
        'recipientEmail': 'admin@system.com',
        'recipientPhone': '',
        'subject': subject,
        'message': message,
        'sender': user.email ?? user.displayName ?? 'User',
        'senderId': user.uid,
        'status': 'sent',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      };

      await _firestore.collection('messages').add(messageData);
    } catch (e) {
      print('Error sending message to admin: $e');
      rethrow;
    }
  }
}