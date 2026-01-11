// providers/property_provider.dart
import 'package:flutter/material.dart';
// import 'auth_provider.dart'; comes from above chunk logic but ensuring imports exist
import '../data/models/property_model.dart';
import '../data/repositories/property_repository.dart';

import 'auth_provider.dart';

class PropertyProvider with ChangeNotifier {
  final PropertyRepository _repository;
  final AuthProvider _authProvider;

  bool _disposed = false;

  PropertyProvider(this._repository, this._authProvider);

  bool get isLandlord => _authProvider.isLandlord;
  bool get isTenant => _authProvider.isTenant;

  List<PropertyModel> _properties = [];
  List<PropertyModel> _filteredProperties = [];
  PropertyModel? _selectedProperty;
  bool _isLoading = false;
  String _searchTerm = '';
  String _filterStatus = 'all';
  Map<String, dynamic> _stats = {};
  String? _error;

  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get filteredProperties => _filteredProperties;
  PropertyModel? get selectedProperty => _selectedProperty;
  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;
  String get filterStatus => _filterStatus;
  Map<String, dynamic> get stats => _stats;
  String? get error => _error;

  Future<void> loadProperties() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? ownerIdFilter;
      String? statusFilter;

      // Role-based filtering
      if (_authProvider.isLandlord) {
        ownerIdFilter = _authProvider.firebaseUser?.uid;
      } else if (_authProvider.isTenant) {
        statusFilter = 'vacant';
      }

      final result = await _repository.getProperties(
        ownerId: ownerIdFilter,
        statusFilter: statusFilter,
      );
      result.fold(
        (failure) {
          _error = failure.message;
        },
        (properties) {
          _properties = properties;
          _filteredProperties = properties;
        },
      );
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      final result = await _repository.getPropertiesStats();
      result.fold(
        (failure) => _error = failure.message,
        (stats) => _stats = stats,
      );
    } catch (e) {
      _error = 'Failed to load statistics';
    }
    if (!_disposed) notifyListeners();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    _applyFilters();
    if (!_disposed) notifyListeners();
  }

  void _applyFilters() {
    _filteredProperties = _properties.where((property) {
      final statusMatches = _filterStatus == 'all' || 
          property.status.value == _filterStatus.toLowerCase();
      
      final searchMatches = _searchTerm.isEmpty ||
          property.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          property.description.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          property.address.fullAddress.toLowerCase().contains(_searchTerm.toLowerCase());

      return statusMatches && searchMatches;
    }).toList();
  }

  Future<void> selectProperty(String propertyId) async {
    try {
      final result = await _repository.getPropertyById(propertyId);
      result.fold(
        (failure) => _error = failure.message,
        (property) => _selectedProperty = property,
      );
    } catch (e) {
      _error = 'Failed to load property details';
    }
    notifyListeners();
  }

  Future<void> updatePropertyStatus(
    String propertyId,
    PropertyStatus newStatus,
  ) async {
    try {
      final result = await _repository.updatePropertyStatus(
        propertyId,
        newStatus,
      );
      
      result.fold(
        (failure) => _error = failure.message,
        (_) {
          // Update local state
          final index = _properties.indexWhere((p) => p.id == propertyId);
          if (index != -1) {
            _properties[index] = _properties[index].copyWith(status: newStatus);
            _applyFilters();
            loadStats(); // Refresh stats
          }
        },
      );
    } catch (e) {
      _error = 'Failed to update property status';
    }
    notifyListeners();
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