import 'package:cloud_firestore/cloud_firestore.dart';

class TenantRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DocumentReference> createTenant(
      Map<String, dynamic> data) async {
    return await _db.collection('tenants').add(data);
  }

  Future<void> occupyUnit({
    required String unitId,
    required String tenantId,
    required String tenantName,
  }) async {
    await _db.collection('units').doc(unitId).update({
      'status': 'occupied',
      'tenantId': tenantId,
      'tenantName': tenantName,
      'occupiedAt': Timestamp.now(),
    });
  }
}
