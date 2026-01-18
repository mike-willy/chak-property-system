import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../../../providers/auth_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/tenant_provider.dart';

// Models
import '../../../data/models/tenant_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/address_model.dart';

// Pages
import '../properties/pages/property_list_page.dart';
import 'messages_page.dart';
import 'maintenance_page.dart';
import 'profile_page.dart';

// Widgets
import '../widgets/header_section.dart';
import '../widgets/tenant_home_card.dart';
import '../widgets/upcoming_rent_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/payment_history_list.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardHome(),
    const PropertyListPage(),
    const MessagesPage(),
    const MaintenancePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141725), // Deep Dark Background
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2235), // Dark Bar Background
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF4E95FF), // Bright Blue
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Rentals'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
            BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined), activeIcon: Icon(Icons.build_circle), label: 'Maint.'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  PropertyModel? _currentProperty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final propertyProvider = context.read<PropertyProvider>();
    final tenantProvider = context.read<TenantProvider>();

    if (propertyProvider.properties.isEmpty) {
      await propertyProvider.loadProperties();
    }
    
    // Trigger Tenant Data Load
    if (authProvider.isTenant && authProvider.firebaseUser != null) {
      await tenantProvider.loadTenantData();
    }
  }

  // Find the property for the loaded tenant
  void _updateCurrentProperty(TenantModel? tenant) {
    if (tenant == null) return;
    
    final propertyProvider = context.read<PropertyProvider>();
    try {
      if (propertyProvider.properties.isNotEmpty) {
        final prop = propertyProvider.properties.firstWhere(
           (p) => p.id == tenant.propertyId,
           orElse: () => _getEmptyProperty(),
        );
         // only update if different to avoid infinite rebuild loops if used incorrectly
         if (_currentProperty?.id != prop.id) {
           setState(() {
             _currentProperty = prop;
           });
         }
      }
    } catch (e) {
      debugPrint('Property find error: $e');
    }
  }

  PropertyModel _getEmptyProperty() {
    return PropertyModel(
      id: '', title: 'Loading...', unitId: '', description: '',
      address: AddressModel(street: '', city: '', state: '', zipCode: ''),
      ownerId: '', ownerName: '', price: 0, deposit: 0, bedrooms: 0, bathrooms: 0, squareFeet: 0,
      amenities: [], images: [], status: PropertyStatus.vacant,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
  }

  void _navigateToPage(int index) {
     final dashboardState = context.findAncestorStateOfType<_DashboardPageState>();
     if (dashboardState != null) {
       dashboardState.setState(() {
         dashboardState._currentIndex = index;
       });
     }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Consumer3<AuthProvider, PropertyProvider, TenantProvider>(
          builder: (context, authProvider, propertyProvider, tenantProvider, _) {
            final isTenant = authProvider.isTenant && tenantProvider.tenant != null;
            final user = authProvider.userProfile;
            
            // Should initiate property retrieval when tenant is loaded
            if (isTenant && _currentProperty == null && propertyProvider.properties.isNotEmpty) {
                // Defer state update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateCurrentProperty(tenantProvider.tenant);
                });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER
                 HeaderSection(
                  userName: user?.name.split(' ')[0] ?? 'User',
                  userRole: authProvider.isTenant ? 'Tenant' : 'Guest',
                  tenantId: isTenant ? tenantProvider.tenant!.id.substring(0, 6) : null,
                  onNotificationTap: () {},
                ),
                
                const SizedBox(height: 24),
                
                if (tenantProvider.isLoading)
                   const Center(child: CircularProgressIndicator(color: Colors.white))
                else if (isTenant) ...[
                  // 2. PROPERTY IMAGE CARD
                  TenantHomeCard(
                    tenantData: tenantProvider.tenant,
                    propertyData: _currentProperty,
                    isLoading: tenantProvider.isLoading,
                    unitNumberOverride: tenantProvider.unit?.unitNumber,
                  ),
                  
                  const SizedBox(height: 20),

                  // 3. RENT DUE CARD
                  UpcomingRentCard(
                    tenantData: tenantProvider.tenant, 
                    isLoading: tenantProvider.isLoading,
                    properties: propertyProvider.properties,
                  ),

                  const SizedBox(height: 20),

                  // 4. ACTION BUTTONS (Report Issue / Lease Terms)
                  QuickActionsGrid(
                    onPayRent: () {}, // Handled in Rent Card usually
                    onRequestMaintenance: () => _navigateToPage(3),
                    onViewMessages: () => _navigateToPage(2),
                    onViewDocuments: () {},
                  ),

                  const SizedBox(height: 25),

                  // 5. PAYMENT HISTORY LIST
                  PaymentHistoryList(
                    payments: tenantProvider.payments,
                    isLoading: tenantProvider.isLoading,
                  ),

                ] else ...[
                   _buildGuestView(),
                ],
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildGuestView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.home_work_outlined, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Looking for a home?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse our available properties and submit an application today.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _navigateToPage(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E86DE),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Browse Properties'),
          ),
        ],
      ),
    );
  }
}