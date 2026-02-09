// data/datasources/remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../models/maintenance_model.dart';
import '../models/maintenance_category_model.dart'; // Added import

class RemoteDataSource {
  final FirebaseFirestore _firestore;

  RemoteDataSource(this._firestore);

  // Maintenance Categories
  Future<List<MaintenanceCategoryModel>> getMaintenanceCategories() async {
    try {
      final querySnapshot = await _firestore.collection('maintenance_categories').get();
      return querySnapshot.docs
          .map((doc) => MaintenanceCategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch maintenance categories: $e');
    }
  }

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
        query = query.where(Filter.or(
          Filter('ownerId', isEqualTo: ownerId),
          Filter('landlordId', isEqualTo: ownerId),
        ));
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

  Future<List<Map<String, dynamic>>> getPropertyUnits(String propertyId) async {
    try {
      final querySnapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch property units: $e');
    }
  }

  Future<Map<String, dynamic>> getPropertyUnit(String propertyId, String unitId) async {
    try {
      final doc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .get();

      if (!doc.exists) {
        throw Exception('Unit not found');
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      throw Exception('Failed to fetch property unit: $e');
    }
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

  Future<UserModel> getLandlordProfile(String userId) async {
    try {
      final doc = await _firestore.collection('landlords').doc(userId).get();
      if (!doc.exists) {
        throw Exception('Landlord profile not found');
      }
      // Assuming landlords collection has similar structure or compatible fields
      // If role is missing in doc, we might need to enforce it
      var data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('role')) {
         data['role'] = 'landlord'; // Enforce role if missing
      }
      // Re-create doc snapshot with potentially modified data? 
      // Or just map it manually. UserModel.fromMap handles it.
      return UserModel.fromMap(doc.id, data);
    } catch (e) {
      throw Exception('Failed to fetch landlord profile: $e');
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

  Future<bool> checkTenantExists(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('tenants')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check tenant existence: $e');
    }
  }

  Future<bool> checkLandlordExists(String userId) async {
    try {
      final doc = await _firestore.collection('landlords').doc(userId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check landlord existence: $e');
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

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshots = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshots.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
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
      final Map<String, dynamic> updates = {
        'status': status.value,
        'updatedAt': Timestamp.now(),
      };

      // Handle special timestamps for status changes
      if (status == MaintenanceStatus.completed) {
        updates['completedAt'] = Timestamp.now();
        updates['onHoldAt'] = null; // Clear on-hold if completing
      } else if (status == MaintenanceStatus.onHold) {
        updates['onHoldAt'] = Timestamp.now();
        updates['completedAt'] = null; // Clear completed if putting on hold
      } else if (status == MaintenanceStatus.canceled) {
        updates['cancelledAt'] = Timestamp.now();
        updates['completedAt'] = null;
        updates['onHoldAt'] = null;
      } else if (status == MaintenanceStatus.open || status == MaintenanceStatus.inProgress) {
        // Clear special timestamps when moving back to normal status
        updates['completedAt'] = null;
        updates['onHoldAt'] = null;
        updates['cancelledAt'] = null;
      }

      await _firestore.collection('maintenance').doc(requestId).update(updates);
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