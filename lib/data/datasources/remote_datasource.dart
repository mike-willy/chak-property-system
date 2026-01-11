// data/datasources/remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

class RemoteDataSource {
  final FirebaseFirestore _firestore;

  RemoteDataSource(this._firestore);

  Future<List<PropertyModel>> getProperties({
    String? statusFilter,
    String? searchTerm,
    String? ownerId,
  }) async {
    try {
      Query query = _firestore.collection('properties');

      if (statusFilter != null && statusFilter != 'all') {
        query = query.where('status', isEqualTo: statusFilter.toLowerCase());
      }

      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }

      final querySnapshot = await query.get();
      
      List<PropertyModel> properties = querySnapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .toList();

      if (searchTerm != null && searchTerm.isNotEmpty) {
        final lowerSearchTerm = searchTerm.toLowerCase();
        properties = properties.where((property) {
          return property.title.toLowerCase().contains(lowerSearchTerm) ||
              property.description.toLowerCase().contains(lowerSearchTerm) ||
              property.address.fullAddress.toLowerCase().contains(lowerSearchTerm);
        }).toList();
      }

      return properties;
    } catch (e) {
      throw Exception('Failed to fetch properties: $e');
    }
  }

  Future<PropertyModel> getPropertyById(String id) async {
    try {
      final doc = await _firestore.collection('properties').doc(id).get();
      if (!doc.exists) {
        throw Exception('Property not found');
      }
      return PropertyModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch property: $e');
    }
  }

  Future<String> addProperty(PropertyModel property) async {
    try {
      final docRef = await _firestore.collection('properties').add(
        property.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toMap(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add property: $e');
    }
  }

  Future<void> updateProperty(PropertyModel property) async {
    try {
      await _firestore.collection('properties').doc(property.id).update(
        property.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw Exception('Failed to update property: $e');
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      await _firestore.collection('properties').doc(propertyId).delete();
    } catch (e) {
      throw Exception('Failed to delete property: $e');
    }
  }

  Future<void> updatePropertyStatus(
    String propertyId,
    PropertyStatus status,
  ) async {
    try {
      await _firestore.collection('properties').doc(propertyId).update({
        'status': status.value,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update property status: $e');
    }
  }

  Future<Map<String, dynamic>> getPropertiesStats() async {
    try {
      final properties = await getProperties();
      
      final total = properties.length;
      final occupied = properties
          .where((p) => p.status == PropertyStatus.occupied)
          .length;
      final vacant = properties
          .where((p) => p.status == PropertyStatus.vacant)
          .length;
      final maintenance = properties
          .where((p) => p.status == PropertyStatus.maintenance)
          .length;

      return {
        'total': total,
        'occupied': occupied,
        'vacant': vacant,
        'maintenance': maintenance,
      };
    } catch (e) {
      throw Exception('Failed to get properties stats: $e');
    }
  }

  Stream<List<PropertyModel>> getPropertiesStream() {
    return _firestore
        .collection('properties')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromFirestore(doc))
            .toList());
  }

  // User Profile Methods
  Future<UserModel> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw Exception('User profile not found');
      }
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // Notification Methods
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      // Admin web writes to 'notifications' collection
      // Assuming notifications have a 'userId' field to filter by
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }
}