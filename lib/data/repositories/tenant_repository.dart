import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant_model.dart';

class TenantRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tenants';

  // Get tenant by user ID
  Future<TenantModel?> getTenantByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .limit(1) // Assuming one tenant per user
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return TenantModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch tenant: $e');
    }
  }

  // Get tenant by email
  Future<TenantModel?> getTenantByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return TenantModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch tenant by email: $e');
    }
  }
  
  // Get tenant by document ID
  Future<TenantModel?> getTenantById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return TenantModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch tenant by id: $e');
    }
  }

  // Create a new tenant
  Future<DocumentReference> createTenant(Map<String, dynamic> tenantData) async {
    try {
      if (tenantData.containsKey('userId') && tenantData['userId'] != null && tenantData['userId'].toString().isNotEmpty) {
        final ref = _firestore.collection(_collection).doc(tenantData['userId']);
        await ref.set(tenantData);
        return ref;
      }
      return await _firestore.collection(_collection).add(tenantData);
    } catch (e) {
      throw Exception('Failed to create tenant: $e');
    }
  }

  // Update tenant status or other fields
  Future<void> updateTenant(String tenantId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(tenantId).update(updates);
    } catch (e) {
      throw Exception('Failed to update tenant: $e');
    }
  }

  // Occupy a unit (update unit with tenant info)
  Future<void> occupyUnit({
    required String unitId,
    required String tenantId,
    required String tenantName,
  }) async {
    try {
      // Assuming units are in a 'units' collection; adjust if needed
      await _firestore.collection('units').doc(unitId).update({
        'tenantId': tenantId,
        'tenantName': tenantName,
        'status': 'occupied',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to occupy unit: $e');
    }
  }

  // Get all tenants (optional, for admin/landlord views)
  Future<List<TenantModel>> getAllTenants() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs.map((doc) => TenantModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tenants: $e');
    }
  }

  // Delete tenant (optional)
  Future<void> deleteTenant(String tenantId) async {
    try {
      await _firestore.collection(_collection).doc(tenantId).delete();
    } catch (e) {
      throw Exception('Failed to delete tenant: $e');
    }
  }
}
