// providers/maintenance_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../data/models/maintenance_model.dart';
import '../data/models/maintenance_category_model.dart'; 
import '../data/repositories/maintenance_repository.dart';
import 'tenant_provider.dart'; 
import 'auth_provider.dart';
import '../core/services/notification_service.dart' as service;
import '../data/models/notification_model.dart';

class MaintenanceProvider with ChangeNotifier {
  final MaintenanceRepository _repository;
  AuthProvider _authProvider;
  TenantProvider? _tenantProvider; // Make nullable to avoid init issues if not provided immediately

  StreamSubscription<List<MaintenanceModel>>? _requestsSubscription;
  bool _disposed = false;

  MaintenanceProvider(this._repository, this._authProvider, [this._tenantProvider]);

  void update(AuthProvider auth, TenantProvider tenant) {
    _authProvider = auth;
    _tenantProvider = tenant;
    _applyFilters(); // Re-apply filters when dependencies change
    notifyListeners();
  }

  bool get isLandlord => _authProvider.isLandlord;
  bool get isTenant => _authProvider.isTenant;

  List<MaintenanceModel> _requests = [];
  List<MaintenanceModel> _filteredRequests = [];
  List<MaintenanceCategoryModel> _categories = [];
  MaintenanceModel? _selectedRequest;
  bool _isLoading = false;
  String _filterStatus = 'all';
  String? _error;

  List<MaintenanceModel> get requests => _requests;
  List<MaintenanceModel> get filteredRequests => _filteredRequests;
  List<MaintenanceCategoryModel> get categories => _categories;
  MaintenanceModel? get selectedRequest => _selectedRequest;
  bool get isLoading => _isLoading;
  String get filterStatus => _filterStatus;
  String? get error => _error;

  Future<void> loadRequests() async {
    // If we're already listening, don't restart subscription unless filters forced a reload (which sets listener to null usually)
    // But here we can just cancel and restart to be safe with new filters
    await _requestsSubscription?.cancel();
    _requestsSubscription = null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? tenantId;
      if (isTenant) {
        tenantId = _authProvider.firebaseUser?.uid;
      }

      final stream = _repository.getMaintenanceRequestsStream(
        tenantId: tenantId,
        statusFilter: _filterStatus != 'all' ? _filterStatus : null,
      );

      _requestsSubscription = stream.listen(
        (newRequests) {
          debugPrint('MaintenanceProvider: Stream received ${newRequests.length} requests');
          
          // Detect NEW requests for Landlord Alerts only
          if (_requests.isNotEmpty) {
            for (final next in newRequests) {
              final prevIndex = _requests.indexWhere((r) => r.id == next.id);
              
              if (prevIndex == -1) {
                // New request detected
                if (isLandlord) {
                  service.NotificationService.sendMaintenanceAlert(
                    userId: _authProvider.userId!,
                    tenantName: next.tenantName,
                    propertyName: next.propertyName,
                    issue: next.title,
                  );
                }
              }
            }
          }

          _requests = newRequests;
          _applyFilters();
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
            _error = 'Error loading requests: $e';
            _isLoading = false;
            debugPrint('MaintenanceProvider: Stream error: $e');
            notifyListeners();
        },
      );
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      debugPrint('MaintenanceProvider: Exception initializing stream: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      final result = await _repository.getMaintenanceCategories();
      result.fold(
        (failure) => debugPrint('Failed to load categories: ${failure.message}'),
        (categories) {
          _categories = categories;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Exception loading categories: $e');
    }
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void _applyFilters() {
    _filteredRequests = _requests.where((request) {
      // 1. Status Filter
      if (_filterStatus != 'all' && request.status.value != _filterStatus) {
        return false;
      }

      // 2. Strict Landlord Filter
      if (isLandlord && _tenantProvider != null) {
         final myTenantIds = _tenantProvider!.tenantsList.map((t) => t.userId).toSet();
         final myTenantDocIds = _tenantProvider!.tenantsList.map((t) => t.id).toSet();
         
         // If tenant list is empty, we effectively hide all requests until it loads
         if (myTenantIds.isEmpty && myTenantDocIds.isEmpty) {
           return false; 
         }

         final matches = myTenantIds.contains(request.tenantId) || myTenantDocIds.contains(request.tenantId);
         if (!matches) return false;
      }

      // 3. Strict Tenant Filter (Safety Check)
      if (isTenant && _authProvider.firebaseUser != null) {
        if (request.tenantId != _authProvider.firebaseUser!.uid) {
          return false;
        }
        // 4. Active Unit Filter (Multi-Tenancy Support)
        // Only show requests for the currently selected unit in the dashboard
        if (_tenantProvider?.tenant != null) {
           if (request.unitId != _tenantProvider!.tenant!.unitId) {
             return false;
           }
        }
      }

      return true;
    }).toList();
  }

  Future<void> createRequest({
    required String unitId,
    required String title,
    required String description,
    required MaintenancePriority priority,
    required String tenantName,
    required String propertyName,
    required String unitName,
    List<String> images = const [],
    String? ownerId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tenantId = _authProvider.firebaseUser?.uid;
      if (tenantId == null) {
        _error = 'User not authenticated';
        return;
      }

      final request = MaintenanceModel(
        id: '', 
        tenantId: tenantId,
        unitId: unitId,
        tenantName: tenantName,
        propertyName: propertyName,
        unitName: unitName,
        title: title,
        description: description,
        priority: priority,
        status: MaintenanceStatus.open,
        images: images,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await _repository.createMaintenanceRequest(request);
      result.fold(
        (failure) {
          _error = failure.message;
        },
        (requestId) async {
          // Notify landlord if ownerId is provided
          if (ownerId != null && ownerId.isNotEmpty) {
            service.NotificationService.sendMaintenanceAlert(
              userId: ownerId,
              tenantName: tenantName,
              propertyName: propertyName,
              issue: title,
            );
          }
          
          loadRequests();
        },
      );
    } catch (e) {
      _error = 'Failed to create maintenance request: $e';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> updateRequestStatus(
    String requestId,
    MaintenanceStatus status,
  ) async {
    try {
      final result = await _repository.updateMaintenanceStatus(requestId, status);
      result.fold(
        (failure) => _error = failure.message,
        (_) {
          // Find the request to send notification
          final index = _requests.indexWhere((r) => r.id == requestId);
          if (index != -1) {
            final request = _requests[index];
            
            // Notify Tenant about status change
            service.NotificationService.sendMaintenanceNotification(
              userId: request.tenantId,
              propertyName: request.propertyName,
              status: status.value,
            );
          }
          
          _applyFilters();
        },
      );
    } catch (e) {
      _error = 'Failed to update maintenance status: $e';
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> selectRequest(String requestId) async {
    try {
      final result = await _repository.getMaintenanceRequestById(requestId);
      result.fold(
        (failure) => _error = failure.message,
        (request) => _selectedRequest = request,
      );
    } catch (e) {
      _error = 'Failed to load maintenance request details: $e';
    }
    if (!_disposed) notifyListeners();
  }

  void clearError() {
    _error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    _disposed = true;
    super.dispose();
  }
}
