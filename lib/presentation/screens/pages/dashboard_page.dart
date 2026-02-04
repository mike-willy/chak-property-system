import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

// Providers
import '../../../providers/auth_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/tenant_provider.dart';
import '../../../providers/application_provider.dart';

// Models
import '../../../data/models/tenant_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/address_model.dart';
import '../../../data/models/application_model.dart';

// Pages
import '../properties/pages/property_list_page.dart';
import '../landlord/pages/analytics_page.dart';
import '../payments/payment_history_page.dart'; 
import 'messages_page.dart';
import 'maintenance_page.dart';
import 'profile_page.dart';

// Widgets
import '../widgets/header_section.dart';
import '../widgets/tenant_home_card.dart';
import '../widgets/upcoming_rent_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/payment_history_list.dart';
import '../widgets/tenant_list_item.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  bool _isLoading = true;

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
    
    if (authProvider.isTenant && authProvider.firebaseUser != null) {
      await tenantProvider.loadTenantData();
    } else if (authProvider.isLandlord && authProvider.firebaseUser != null) {
      final myPropertyIds = propertyProvider.properties
          .where((p) => p.ownerId == authProvider.userId)
          .map((p) => p.id)
          .toList();
      await tenantProvider.loadLandlordTenants(myPropertyIds);
      await context.read<ApplicationProvider>().loadLandlordApplications(myPropertyIds);
    } else if (authProvider.isAdmin && authProvider.firebaseUser != null) {
      await tenantProvider.loadAllTenants();
      await context.read<ApplicationProvider>().loadPending();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentIndex = 0; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, TenantProvider>(
      builder: (context, authProvider, tenantProvider, _) {
        if (authProvider.loggedIn && authProvider.userProfile == null) {
           return const Scaffold(
             backgroundColor: Color(0xFF141725),
             body: Center(child: CircularProgressIndicator(color: Color(0xFF4D95FF))),
           );
        }

        final isLandlordOrAdmin = authProvider.isLandlord || authProvider.isAdmin;
        final isNewTenant = authProvider.isTenant && tenantProvider.tenant == null;

        List<Widget> pages;
        List<BottomNavigationBarItem> navItems;

        if (isNewTenant) {
          pages = [
              const PropertyListPage(),
              const DashboardHome(),
              const ProfilePage(),
          ];
          navItems = const [
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Status'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ];
        } else {
          // FIX: Removed 'const' from this list to resolve the build error
          pages = [
            const DashboardHome(),           
            const PropertyListPage(),        
            const PaymentHistoryPage(),  
            const MaintenancePage(),    
            if (isLandlordOrAdmin) const AnalyticsPage() else const MessagesPage(), 
            const ProfilePage(),             
          ];

          navItems = [
            const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: const Icon(Icons.search), label: isLandlordOrAdmin ? 'Properties' : 'Rentals'),
            const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'History'),
            const BottomNavigationBarItem(icon: Icon(Icons.build_outlined), activeIcon: Icon(Icons.build), label: 'Maintenance'),
            if (isLandlordOrAdmin)
              const BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Analytics')
            else
              const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ];
        }

        if (_currentIndex >= pages.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          backgroundColor: const Color(0xFF141725),
          body: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4D95FF)))
              : IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E2235),
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
              selectedItemColor: const Color(0xFF4E95FF),
              unselectedItemColor: Colors.grey.shade600,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: navItems,
            ),
          ),
        );
      },
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
    
    if (authProvider.isTenant && authProvider.firebaseUser != null) {
      await tenantProvider.loadTenantData();
    } else if (authProvider.isLandlord && authProvider.firebaseUser != null) {
      final myPropertyIds = propertyProvider.properties
          .where((p) => p.ownerId == authProvider.userId)
          .map((p) => p.id)
          .toList();
      await tenantProvider.loadLandlordTenants(myPropertyIds);
      await context.read<ApplicationProvider>().loadLandlordApplications(myPropertyIds);
    } else if (authProvider.isAdmin && authProvider.firebaseUser != null) {
      await tenantProvider.loadAllTenants();
      await context.read<ApplicationProvider>().loadPending();
    }
  }

  void _updateCurrentProperty(TenantModel? tenant) {
    if (tenant == null) return;
    final propertyProvider = context.read<PropertyProvider>();
    try {
      if (propertyProvider.properties.isNotEmpty) {
        final prop = propertyProvider.properties.firstWhere(
            (p) => p.id == tenant.propertyId,
            orElse: () => _getEmptyProperty(),
        );
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
            final user = authProvider.userProfile;
            final applicationProvider = context.watch<ApplicationProvider>();
            final isTenant = authProvider.isTenant && tenantProvider.tenant != null;
            
            if (isTenant && _currentProperty == null && propertyProvider.properties.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateCurrentProperty(tenantProvider.tenant);
                });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderSection(
                  userName: user?.name.split(' ')[0] ?? 'User',
                  userRole: authProvider.isTenant ? 'Tenant' : (authProvider.isLandlord ? 'Landlord' : (authProvider.isAdmin ? 'Admin' : 'Guest')),
                  tenantId: isTenant ? tenantProvider.tenant!.id.substring(0, 6) : null,
                  onNotificationTap: () {},
                ),
                const SizedBox(height: 24),
                
                if (tenantProvider.isLoading)
                   const Center(child: CircularProgressIndicator(color: Colors.white))
                else if (isTenant) ...[
                  TenantHomeCard(
                    tenantData: tenantProvider.tenant,
                    propertyData: _currentProperty,
                    isLoading: tenantProvider.isLoading,
                    unitNumberOverride: tenantProvider.unit?.unitNumber,
                  ),
                  const SizedBox(height: 20),
                  UpcomingRentCard(
                    tenantData: tenantProvider.tenant, 
                    isLoading: tenantProvider.isLoading,
                    properties: propertyProvider.properties,
                  ),
                  const SizedBox(height: 20),
                  QuickActionsGrid(
                    onPayRent: () {}, 
                    onRequestMaintenance: () => _navigateToPage(3), 
                    onViewMessages: () => _navigateToPage(3),    
                    onViewDocuments: () => _navigateToPage(2),   
                  ),
                  const SizedBox(height: 25),
                  PaymentHistoryList(
                    payments: tenantProvider.payments,
                    isLoading: tenantProvider.isLoading,
                  ),
                ] else if (authProvider.isTenant) ...[
                  _buildTenantApplicationStatus(authProvider, applicationProvider),
                ] else if (authProvider.isLandlord || authProvider.isAdmin) ...[
                   _buildLandlordView(tenantProvider, applicationProvider),
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

  Widget _buildLandlordView(TenantProvider tenantProvider, ApplicationProvider applicationProvider) {
    final tenants = tenantProvider.tenantsList;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (applicationProvider.applications.isNotEmpty) ...[
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pending Applications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Manage', style: TextStyle(color: Color(0xFF4E95FF), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: applicationProvider.applications.length,
            itemBuilder: (context, index) {
              final app = applicationProvider.applications[index];
              return Card(
                color: const Color(0xFF1E2235),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(app.propertyName ?? 'New Application', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Applicant: ${app.fullName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: ElevatedButton(
                    onPressed: () => _showApprovalDialog(context, app),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Review', style: TextStyle(fontSize: 12)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        const Text('Approved Tenants', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        if (tenants.isEmpty)
          const Text('No Tenants Yet', style: TextStyle(color: Colors.grey))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tenants.length,
            itemBuilder: (context, index) => TenantListItem(tenant: tenants[index], onTap: () {}),
          ),
      ],
    );
  }

  Widget _buildTenantApplicationStatus(AuthProvider authProvider, ApplicationProvider applicationProvider) {
    return StreamBuilder<List<ApplicationModel>>(
      stream: applicationProvider.getTenantApplicationsStream(authProvider.userId ?? ''),
      builder: (context, snapshot) {
        final apps = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (apps.isNotEmpty) ...[
              const Text('Your Applications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              ...apps.map((app) => Card(
                color: const Color(0xFF1E2235),
                child: ListTile(
                  title: Text(app.propertyName ?? 'Application', style: const TextStyle(color: Colors.white)),
                  trailing: Text(app.status.name.toUpperCase(), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              )).toList(),
            ],
            _buildGuestView(),
          ],
        );
      },
    );
  }

  Widget _buildGuestView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1E2235), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Icon(Icons.home_work_outlined, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('Looking for a home?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => _navigateToPage(1), child: const Text('Browse Properties')),
        ],
      ),
    );
  }

  void _showApprovalDialog(BuildContext context, ApplicationModel application) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('Approve Application', style: TextStyle(color: Colors.white)),
        content: Text('Approve ${application.fullName} for ${application.propertyName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final tenantData = {
                'userId': application.tenantId,
                'fullName': application.fullName,
                'email': application.email,
                'propertyId': application.propertyId,
                'propertyName': application.propertyName,
                'unitId': application.unitId,
                'unitNumber': application.unitNumber,
                'rentAmount': application.monthlyRent,
                'status': 'active',
                'createdAt': firestore.Timestamp.now(),
              };
              await context.read<ApplicationProvider>().convertToTenant(application: application, tenantData: tenantData);
            },
            child: const Text('Approve & Convert'),
          ),
        ],
      ),
    );
  }
}