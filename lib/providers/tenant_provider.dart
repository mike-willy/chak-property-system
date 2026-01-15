import 'package:flutter/foundation.dart';
import '../data/models/tenant_model.dart';
import '../data/models/payment_model.dart';
import '../data/models/unit_model.dart'; // Added import
import '../data/repositories/tenant_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/property_repository.dart'; // Added import
import 'auth_provider.dart';

class TenantProvider with ChangeNotifier {
  final TenantRepository _tenantRepository;
  final PaymentRepository _paymentRepository;
  final PropertyRepository _propertyRepository; // Added repository
  AuthProvider _authProvider;

  TenantModel? _tenant;
  List<PaymentModel> _payments = [];
  UnitModel? _unit; // Added unit
  bool _isLoading = false;
  String? _error;

  bool _disposed = false;

  TenantProvider(
    this._tenantRepository, 
    this._paymentRepository, 
    this._propertyRepository, // Added to constructor
    this._authProvider
  );
  
  void update(AuthProvider auth) {
    _authProvider = auth;
    notifyListeners(); 
  }

  TenantModel? get tenant => _tenant;
  List<PaymentModel> get payments => _payments;
  UnitModel? get unit => _unit; // Added getter

  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<void> loadTenantData() async {
    final user = _authProvider.firebaseUser;
    if (user == null) {
      _tenant = null;
      _payments = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify start of loading

    try {
      // 1. Fetch Tenant
      _tenant = await _tenantRepository.getTenantByUserId(user.uid);
      
      if (_tenant != null) {
        // 2. Fetch Payments if tenant exists
        _payments = await _paymentRepository.getPaymentsByTenantId(_tenant!.id);

        // 3. Fetch Unit details if propertyId and unitId are available
        if (_tenant!.propertyId.isNotEmpty && _tenant!.unitId.isNotEmpty) {
           final unitResult = await _propertyRepository.getPropertyUnit(_tenant!.propertyId, _tenant!.unitId);
           unitResult.fold(
            (failure) => debugPrint("TenantProvider: Failed to load unit: ${failure.message}"),
            (unit) => _unit = unit,
           );
        }
      } else {
        _payments = [];
        _unit = null;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint("TenantProvider: Error loading data: $e");
    } finally {
      if (!_disposed) {
          _isLoading = false;
          notifyListeners();
      }
    }
  }

  void clearData() {
    _tenant = null;
    _payments = [];
    _error = null;
    notifyListeners();
  }
}
