import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant_model.dart';

class TenantRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tenants';

  // Get tenant by user ID (Returns list for multi-unit support)
  Future<List<TenantModel>> getAllTenantsByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => TenantModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user tenants: $e');
    }
  }

  // Get single tenant by user ID (First one - for backward compatibility where needed)
  Future<TenantModel?> getTenantByUserId(String userId) async {
    try {
      final tenants = await getAllTenantsByUserId(userId);
      return tenants.isNotEmpty ? tenants.first : null;
    } catch (e) {
      throw Exception('Failed to fetch tenant: $e');
    }
  }

  // Get ALL tenants by email
  Future<List<TenantModel>> getAllTenantsByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .get();

      return querySnapshot.docs
          .map((doc) => TenantModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tenants by email: $e');
    }
  }

  // Get single tenant by email (First one)
  Future<TenantModel?> getTenantByEmail(String email) async {
    try {
      final tenants = await getAllTenantsByEmail(email);
      return tenants.isNotEmpty ? tenants.first : null;
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
      throw Exception('Failed to fetch tenant by ID: $e');
    }
  }

  Future<DocumentReference> createTenant(Map<String, dynamic> tenantData) async {
    try {
      // Use add() to let Firestore generate a unique ID
      // This prevents overwriting when a user has multiple units
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
