import 'package:flutter/material.dart';
import '../data/models/application_model.dart';
import '../data/repositories/application_repository.dart';
import '../data/repositories/tenant_repository.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApplicationRepository _applicationRepo;
  final TenantRepository _tenantRepo;

  ApplicationProvider(
    this._applicationRepo,
    this._tenantRepo,
  );

  bool loading = false;
  List<ApplicationModel> applications = [];

  Future<void> loadPending() async {
    applications = await _applicationRepo.getPendingApplications();
    notifyListeners();
  }
  
  Future<void> loadLandlordApplications(List<String> propertyIds) async {
    loading = true;
    notifyListeners();
    
    try {
      List<ApplicationModel> allApps = [];
      for (final id in propertyIds) {
        final apps = await _applicationRepo.getApplicationsByProperty(id);
        allApps.addAll(apps);
      }
      applications = allApps;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // UPDATED: Now accepts email as optional parameter
  Stream<List<ApplicationModel>> getTenantApplicationsStream(String tenantId, {String? email}) {
    // If email is provided, use it (more reliable for finding all user applications)
    if (email != null && email.isNotEmpty) {
      return _applicationRepo.getApplicationsByEmailStream(email);
    }
    // Otherwise fall back to tenantId
    return _applicationRepo.getTenantApplicationsStream(tenantId);
  }

  Future<void> convertToTenant({
    required ApplicationModel application,
    required Map<String, dynamic> tenantData,
  }) async {
    loading = true;
    notifyListeners();

    try {
      final tenantRef =
          await _tenantRepo.createTenant(tenantData);

      await _tenantRepo.occupyUnit(
        unitId: application.unitId,
        tenantId: tenantRef.id,
        tenantName: tenantData['fullName'],
      );

      await _applicationRepo.approveApplication(
        application: application,
        generatedTenantId: tenantRef.id,
      );

      applications.removeWhere((a) => a.id == application.id);
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}