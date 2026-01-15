// providers/maintenance_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../data/models/maintenance_model.dart';
import '../data/models/maintenance_category_model.dart'; // Added
import '../data/repositories/maintenance_repository.dart';
import 'auth_provider.dart';

class MaintenanceProvider with ChangeNotifier {
  final MaintenanceRepository _repository;
  AuthProvider _authProvider;

  bool _disposed = false;

  MaintenanceProvider(this._repository, this._authProvider);

  void update(AuthProvider auth) {
    _authProvider = auth;
    notifyListeners();
  }

  bool get isLandlord => _authProvider.isLandlord;
  bool get isTenant => _authProvider.isTenant;

  List<MaintenanceModel> _requests = [];
  List<MaintenanceModel> _filteredRequests = [];
  List<MaintenanceCategoryModel> _categories = []; // Added
  MaintenanceModel? _selectedRequest;
  bool _isLoading = false;
  String _filterStatus = 'all';
  String? _error;

  List<MaintenanceModel> get requests => _requests;
  List<MaintenanceModel> get filteredRequests => _filteredRequests;
  List<MaintenanceCategoryModel> get categories => _categories; // Added
  MaintenanceModel? get selectedRequest => _selectedRequest;
  bool get isLoading => _isLoading;
  String get filterStatus => _filterStatus;
  String? get error => _error;

  Future<void> loadRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? tenantId;
      if (isTenant) {
        tenantId = _authProvider.firebaseUser?.uid;
      }

      final result = await _repository.getMaintenanceRequests(
        tenantId: tenantId,
        statusFilter: _filterStatus != 'all' ? _filterStatus : null,
      );

      result.fold(
        (failure) {
          _error = failure.message;
          debugPrint('MaintenanceProvider: Error loading requests: ${failure.message}');
        },
        (requests) {
          debugPrint('MaintenanceProvider: Loaded ${requests.length} maintenance requests');
          _requests = requests;
          _applyFilters();
        },
      );
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      debugPrint('MaintenanceProvider: Exception loading requests: $e');
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    // Don't show global loading state for categories background fetch if requests are already loaded
    // But initially it might be good. Let's just create a separate isLoadingCategories if needed,
    // or use the same one. For simplicity, reusing _isLoading or just fetching quietly.
    // Let's fetch quietly but update UI when done.
    
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
      // Filter by status if needed
      if (_filterStatus != 'all' && request.status.value != _filterStatus) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> createRequest({
    required String unitId,
    required String title,
    required String description,
    required MaintenancePriority priority,
    List<String> images = const [],
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
        id: '', // Will be set by repository
        tenantId: tenantId,
        unitId: unitId,
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
        (_) {
          // Reload requests after creating
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
          // Update local state
          final index = _requests.indexWhere((r) => r.id == requestId);
          if (index != -1) {
            _requests[index] = _requests[index].copyWith(
              status: status,
              updatedAt: DateTime.now(),
            );
            _applyFilters();
          }
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
    _disposed = true;
    super.dispose();
  }
}

