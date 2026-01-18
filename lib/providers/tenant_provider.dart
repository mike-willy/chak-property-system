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
  List<TenantModel> _tenantsList = []; // Added for landlords/admins
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
  List<TenantModel> get tenantsList => _tenantsList; // Added getter
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
    debugPrint("TenantProvider: loadTenantData for user: ${user?.uid}");
    if (user == null) {
      _tenant = null;
      _payments = [];
      _tenantsList = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify start of loading

    try {
      // 1. Fetch Tenant
      _tenant = await _tenantRepository.getTenantByUserId(user.uid);
      debugPrint("TenantProvider: Query by userId: ${user.uid} found: ${_tenant?.id}");
      
      // Fallback 1: Check if document ID is the userId (some systems use UID as doc ID)
      if (_tenant == null) {
         try {
           final doc = await _tenantRepository.getTenantById(user.uid);
           if (doc != null) {
             _tenant = doc;
             debugPrint("TenantProvider: Found tenant by document ID fallback: ${_tenant?.id}");
           }
         } catch (e) {
           debugPrint("TenantProvider: Fallback fetch failed: $e");
         }
      }
      
      // Fallback 2: Email (very useful for legacy records or pre-registrations)
      if (_tenant == null && user.email != null) {
          _tenant = await _tenantRepository.getTenantByEmail(user.email!);
          if (_tenant != null) {
             debugPrint("TenantProvider: Found tenant by email: ${user.email}");
             // Automatically link UID if it's missing or different, to speed up future lookups
             if (_tenant!.userId != user.uid) {
                await _tenantRepository.updateTenant(_tenant!.id, {'userId': user.uid});
                _tenant = _tenant!.copyWith(userId: user.uid);
                debugPrint("TenantProvider: Linked tenant record to UID: ${user.uid}");
             }
          }
      }
      
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

  Future<void> loadAllTenants() async {
    debugPrint("TenantProvider: loadAllTenants");
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tenantsList = await _tenantRepository.getAllTenants();
    } catch (e) {
      _error = e.toString();
      debugPrint("TenantProvider: Error loading all tenants: $e");
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadLandlordTenants(List<String> propertyIds) async {
    debugPrint("TenantProvider: loadLandlordTenants for ${propertyIds.length} properties");
    if (propertyIds.isEmpty) {
      _tenantsList = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final allTenants = await _tenantRepository.getAllTenants();
      _tenantsList = allTenants.where((t) => propertyIds.contains(t.propertyId)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint("TenantProvider: Error loading landlord tenants: $e");
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
    _tenantsList = [];
    _error = null;
    notifyListeners();
  }
}
