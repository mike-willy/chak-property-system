import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';

class ApplicationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _ref =>
      _db.collection('tenantApplications');

  Future<List<ApplicationModel>> getPendingApplications() async {
    final snap =
        await _ref.where('status', isEqualTo: 'pending').get();

    return snap.docs
        .map((d) => ApplicationModel.fromFirestore(d))
        .toList();
  }
  
  Future<List<ApplicationModel>> getApplicationsByProperty(String propertyId) async {
    final snap = await _ref
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'pending')
        .get();
        
    return snap.docs
        .map((d) => ApplicationModel.fromFirestore(d))
        .toList();
  }

  Stream<List<ApplicationModel>> getTenantApplicationsStream(String tenantId) {
    return _ref
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('appliedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => ApplicationModel.fromFirestore(d))
            .toList());
  }

  // NEW METHOD: Get applications by user email (more reliable)
  Stream<List<ApplicationModel>> getApplicationsByEmailStream(String email) {
    return _ref
        .where('email', isEqualTo: email)
        .orderBy('appliedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => ApplicationModel.fromFirestore(d))
            .toList());
  }

  Future<void> approveApplication({
    required ApplicationModel application,
    required String generatedTenantId,
  }) async {
    await _ref.doc(application.id).update({
      'status': 'approved',
      'processedAt': Timestamp.now(),
      'linkedTenantId': generatedTenantId,
    });
  }

  Future<void> rejectApplication({
    required String applicationId,
    required String reason,
  }) async {
    await _ref.doc(applicationId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'processedAt': Timestamp.now(),
    });
  }
}