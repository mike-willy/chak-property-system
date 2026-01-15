// data/datasources/remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../models/maintenance_model.dart';

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

  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
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

  // Maintenance Request Methods
  Future<List<MaintenanceModel>> getMaintenanceRequests({
    String? tenantId,
    String? propertyId,
    String? statusFilter,
  }) async {
    try {
      Query query = _firestore.collection('maintenance');

      if (tenantId != null) {
        query = query.where('tenantId', isEqualTo: tenantId);
      }

      if (statusFilter != null && statusFilter != 'all') {
        query = query.where('status', isEqualTo: statusFilter);
      }

      final querySnapshot = await query.orderBy('createdAt', descending: true).get();

      List<MaintenanceModel> requests = querySnapshot.docs
          .map((doc) => MaintenanceModel.fromFirestore(doc))
          .toList();

      // Filter by propertyId if provided (need to check unit's propertyId)
      if (propertyId != null) {
        // Note: This requires fetching units to match propertyId
        // For now, we'll filter in memory if needed
        // In production, you might want to add propertyId to maintenance model
      }

      return requests;
    } catch (e) {
      throw Exception('Failed to fetch maintenance requests: $e');
    }
  }

  Future<MaintenanceModel> getMaintenanceRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection('maintenance').doc(requestId).get();
      if (!doc.exists) {
        throw Exception('Maintenance request not found');
      }
      return MaintenanceModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch maintenance request: $e');
    }
  }

  Future<String> createMaintenanceRequest(MaintenanceModel request) async {
    try {
      final docRef = await _firestore.collection('maintenance').add(
        request.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toMap(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create maintenance request: $e');
    }
  }

  Future<void> updateMaintenanceRequest(MaintenanceModel request) async {
    try {
      await _firestore.collection('maintenance').doc(request.id).update(
        request.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw Exception('Failed to update maintenance request: $e');
    }
  }

  Future<void> updateMaintenanceStatus(
    String requestId,
    MaintenanceStatus status,
  ) async {
    try {
      await _firestore.collection('maintenance').doc(requestId).update({
        'status': status.value,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update maintenance status: $e');
    }
  }

  Future<void> deleteMaintenanceRequest(String requestId) async {
    try {
      await _firestore.collection('maintenance').doc(requestId).delete();
    } catch (e) {
      throw Exception('Failed to delete maintenance request: $e');
    }
  }

  Stream<List<MaintenanceModel>> getMaintenanceRequestsStream({
    String? tenantId,
    String? statusFilter,
  }) {
    Query query = _firestore.collection('maintenance');

    if (tenantId != null) {
      query = query.where('tenantId', isEqualTo: tenantId);
    }

    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceModel.fromFirestore(doc))
            .toList());
  }
}