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

  // Active tenant (current context)
  TenantModel? _tenant;
  // All tenancies for this user
  List<TenantModel> _userTenancies = [];
  
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
  List<TenantModel> get userTenancies => _userTenancies;
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
      _userTenancies = [];
      _payments = [];
      _tenantsList = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify start of loading

    try {
      // 1. Fetch Tenancies for this user by UID
      _userTenancies = await _tenantRepository.getAllTenantsByUserId(user.uid);
      debugPrint("TenantProvider: Found ${_userTenancies.length} tenancies for userId: ${user.uid}");

      // 2. ALWAYS Check for unregistered units by Email (to support new assignments)
      if (user.email != null) {
          final tenantsByEmail = await _tenantRepository.getAllTenantsByEmail(user.email!);
          
          bool newLinksFound = false;
          for (var tenantRecord in tenantsByEmail) {
             // If found by email but NOT yet linked to this UID
             if (tenantRecord.userId != user.uid) {
                await _tenantRepository.updateTenant(tenantRecord.id, {'userId': user.uid});
                
                // Add to current session list if not already there (safety check)
                if (!_userTenancies.any((t) => t.id == tenantRecord.id)) {
                   _userTenancies.add(tenantRecord.copyWith(userId: user.uid));
                }
                newLinksFound = true;
                debugPrint("TenantProvider: linked unit ${tenantRecord.unitNumber} from ${tenantRecord.propertyName} to UID: ${user.uid}");
             }
          }
          
          if (newLinksFound) {
             debugPrint("TenantProvider: Refreshing tenancies after email linking. Total: ${_userTenancies.length}");
          }
      }
      
      // 2. Set Active Tenant (Default to first one if available)
      if (_userTenancies.isNotEmpty) {
        _tenant = _userTenancies.first; 
      } else {
        _tenant = null;
      }
      
      if (_tenant != null) {
        await _loadActiveTenantDetails();
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

  // Helper to load details for the currently active tenant
  Future<void> _loadActiveTenantDetails() async {
    if (_tenant == null) return;
    
    try {
        // Fetch Payments
        _payments = await _paymentRepository.getPaymentsByTenantId(_tenant!.id);

        // Fetch Unit details
        if (_tenant!.propertyId.isNotEmpty && _tenant!.unitId.isNotEmpty) {
           final unitResult = await _propertyRepository.getPropertyUnit(_tenant!.propertyId, _tenant!.unitId);
           unitResult.fold(
            (failure) => debugPrint("TenantProvider: Failed to load unit: ${failure.message}"),
            (unit) => _unit = unit,
           );
        }
    } catch (e) {
      debugPrint('Error loading active tenant details: $e');
    }
  }

  // Switch active tenant context
  Future<void> switchTenant(TenantModel newTenant) async {
    // Verify this tenant belongs to user
    if (!_userTenancies.any((t) => t.id == newTenant.id)) return;

    _tenant = newTenant;
    _isLoading = true;
    notifyListeners();

    await _loadActiveTenantDetails();

    _isLoading = false;
    notifyListeners();
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
      final activeTenants = await _tenantRepository.getActiveTenants();
      final filteredTenants = activeTenants.where((t) => propertyIds.contains(t.propertyId)).toList();
      
      // Populate rentAmount from Property if missing
      List<TenantModel> enrichedTenants = [];
      for (var tenant in filteredTenants) {
         if (tenant.rentAmount == 0 && tenant.propertyId.isNotEmpty) {
            try {
               final propertyResult = await _propertyRepository.getPropertyById(tenant.propertyId);
               final enrichedTenant = propertyResult.fold(
                 (failure) => tenant, // Keep original if fetch fails
                 (property) => tenant.copyWith(rentAmount: property.price),
               );
               enrichedTenants.add(enrichedTenant);
            } catch (e) {
               enrichedTenants.add(tenant);
            }
         } else {
            enrichedTenants.add(tenant);
         }
      }
      
      _tenantsList = enrichedTenants;
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

  Future<double> calculateTotalCollectedRevenue() async {
    if (_tenantsList.isEmpty) return 0.0;

    double total = 0.0;
    // Iterate through all tenants and fetch their payments
    // This could be optimized with a backend aggregation query in a real production app
    for (final tenant in _tenantsList) {
      try {
        final payments = await _paymentRepository.getPaymentsByTenantId(tenant.id);
        for (final payment in payments) {
          if (payment.status.value == 'completed' || payment.status.value == 'paid') {
             total += payment.amount;
          }
        }
      } catch (e) {
        debugPrint('Error fetching payments for tenant ${tenant.id}: $e');
      }
    }
    return total;
  }

  void clearData() {
    _tenant = null;
    _payments = [];
    _tenantsList = [];
    _error = null;
    notifyListeners();
  }
}
