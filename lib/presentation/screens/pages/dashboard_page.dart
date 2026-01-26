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
import 'messages_page.dart';
import 'maintenance_page.dart';
import 'profile_page.dart';

// Widgets
import '../widgets/header_section.dart';
import '../widgets/tenant_home_card.dart';
import '../widgets/upcoming_rent_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/payment_history_list.dart';
import '../widgets/tenant_list_item.dart'; // Added import

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
    
    // Always load properties
    if (propertyProvider.properties.isEmpty) {
      await propertyProvider.loadProperties();
    }
    
    debugPrint("DashboardPage: Loading data for role=${authProvider.userProfile?.role}");
    
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
        // If it's a new tenant (no active lease), default to Properties page (Index 0 in restricted view)
        // If it's an approved tenant or landlord, default to Home (Index 0 in full view)
        _currentIndex = 0; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to providers to determine content
    return Consumer2<AuthProvider, TenantProvider>(
      builder: (context, authProvider, tenantProvider, _) {
        
        // Determine Status
        final isLandlordOrAdmin = authProvider.isLandlord || authProvider.isAdmin;
        final isApprovedTenant = authProvider.isTenant && tenantProvider.tenant != null;
        final isNewTenant = authProvider.isTenant && tenantProvider.tenant == null;

        // Define Pages
        List<Widget> pages;
        List<BottomNavigationBarItem> navItems;

        if (isNewTenant) {
          // --- NEW / PENDING TENANT VIEW ---
          // 1. Properties (Browse)
          // 2. Home (Application Status)
          // 3. Profile
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
          // --- FULL VIEW (Approved Tenant / Landlord / Admin) ---
          // 1. Home (Dashboard)
          // 2. Properties (My Properties / Rentals)
          // 3. Messages / Analytics
          // 4. Maintenance
          // 5. Profile
          pages = [
            const DashboardHome(),
            const PropertyListPage(),
            if (isLandlordOrAdmin) const AnalyticsPage() else const MessagesPage(),
            const MaintenancePage(),
            const ProfilePage(),
          ];

          navItems = [
            const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: const Icon(Icons.search), label: isLandlordOrAdmin ? 'Properties' : 'Rentals'),
            if (isLandlordOrAdmin)
              const BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Analytics')
            else
              const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
            
            const BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined), activeIcon: Icon(Icons.build_circle), label: 'Maint.'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ];
        }

        // Safety check for index
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
    
    // Trigger Tenant Data Load based on role
    debugPrint("DashboardHome: isTenant=${authProvider.isTenant}, isLandlord=${authProvider.isLandlord}, role=${authProvider.userProfile?.role}");
    
    if (authProvider.isTenant && authProvider.firebaseUser != null) {
      debugPrint("DashboardHome: Loading tenant data...");
      await tenantProvider.loadTenantData();
    } else if (authProvider.isLandlord && authProvider.firebaseUser != null) {
      final myPropertyIds = propertyProvider.properties
          .where((p) => p.ownerId == authProvider.userId)
          .map((p) => p.id)
          .toList();
      debugPrint("DashboardHome: Loading landlord data for ${myPropertyIds.length} properties (Total props: ${propertyProvider.properties.length})");
      await tenantProvider.loadLandlordTenants(myPropertyIds);
      await context.read<ApplicationProvider>().loadLandlordApplications(myPropertyIds);
    } else if (authProvider.isAdmin && authProvider.firebaseUser != null) {
      debugPrint("DashboardHome: Loading admin data...");
      await tenantProvider.loadAllTenants();
      await context.read<ApplicationProvider>().loadPending();
    } else {
      debugPrint("DashboardHome: No specific data loading path for current role (isTenant: ${authProvider.isTenant}, isLandlord: ${authProvider.isLandlord}, isAdmin: ${authProvider.isAdmin})");
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
            final user = authProvider.userProfile;
            final applicationProvider = context.watch<ApplicationProvider>();
            
            // 1. GATHER DATA
            final isTenant = authProvider.isTenant && tenantProvider.tenant != null;
            
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
                  userRole: authProvider.isTenant ? 'Tenant' : (authProvider.isLandlord ? 'Landlord' : (authProvider.isAdmin ? 'Admin' : 'Guest')),
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

                ] else if (authProvider.isTenant) ...[
                  // 6. TENANT BUT NO ACTIVE LEASE (APPLICANT VIEW)
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
        // Pending Applications Section
        if (applicationProvider.applications.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Applications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Manage',
                  style: TextStyle(
                    color: Color(0xFF4E95FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'New tenants waiting for your approval',
            style: TextStyle(color: Colors.grey, fontSize: 13),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4E95FF).withOpacity(0.1),
                    child: const Icon(Icons.person_add, color: Color(0xFF4E95FF)),
                  ),
                  title: Text(
                    app.propertyName ?? 'New Application',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Unit: ${app.unitNumber ?? app.unitName ?? "N/A"} • ${app.tenantId.substring(0, 6)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showApprovalDialog(context, app);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(60, 32),
                    ),
                    child: const Text('Review', style: TextStyle(fontSize: 12)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
        ],

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Approved Tenants',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your active residents and their leases.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 20),
        
        if (tenantProvider.isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(color: Color(0xFF4E95FF)),
          ))
        else if (tenants.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2235),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                const Text(
                  'No Tenants Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Approved tenants will appear here once they are assigned to a property.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              return TenantListItem(
                tenant: tenants[index],
                onTap: () {
                  // Navigate to tenant details if needed
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildTenantApplicationStatus(AuthProvider authProvider, ApplicationProvider applicationProvider) {
    return StreamBuilder<List<ApplicationModel>>(
      stream: applicationProvider.getTenantApplicationsStream(authProvider.userId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }
        
        final apps = snapshot.data ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (apps.isNotEmpty) ...[
              const Text(
                'Your Applications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              ...apps.map((app) => Card(
                color: const Color(0xFF1E2235),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x334E95FF),
                    child: Icon(Icons.description, color: Color(0xFF4E95FF)),
                  ),
                  title: Text(
                    app.propertyName ?? 'Application',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Unit: ${app.unitNumber ?? "N/A"} • Applied: ${app.appliedDate.day}/${app.appliedDate.month}/${app.appliedDate.year}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(app.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor(app.status).withOpacity(0.5)),
                    ),
                    child: Text(
                      app.status.name.toUpperCase(),
                      style: TextStyle(color: _getStatusColor(app.status), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )).toList(),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),
            ],
            
            // Still show the Browse Properties if they have no active lease
            _buildGuestView(),
          ],
        );
      },
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.approved: return Colors.green;
      case ApplicationStatus.rejected: return Colors.red;
      case ApplicationStatus.pending: return Colors.orange;
      default: return Colors.grey;
    }
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

  void _showApprovalDialog(BuildContext context, ApplicationModel application) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('Approve Application', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Applicant: ${application.fullName ?? "Unknown"}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Property: ${application.propertyName ?? "N/A"}', style: const TextStyle(color: Colors.white70)),
            Text('Unit: ${application.unitNumber ?? "N/A"}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const Text(
              'Approving will create a tenant record and assign the unit. The application status will be updated to "Approved".',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              // Prepare tenant data from application
              final tenantData = {
                'userId': application.tenantId,
                'fullName': application.fullName,
                'email': application.email,
                'phone': application.phone,
                'propertyId': application.propertyId,
                'propertyName': application.propertyName,
                'unitId': application.unitId,
                'unitNumber': application.unitNumber,
                'rentAmount': application.monthlyRent,
                'leaseStartDate': application.leaseStart != null ? firestore.Timestamp.fromDate(application.leaseStart!) : firestore.Timestamp.now(),
                'leaseEndDate': application.leaseEnd != null ? firestore.Timestamp.fromDate(application.leaseEnd!) : firestore.Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
                'status': 'active',
                'createdAt': firestore.Timestamp.now(),
                'updatedAt': firestore.Timestamp.now(),
              };

              try {
                await context.read<ApplicationProvider>().convertToTenant(
                  application: application,
                  tenantData: tenantData,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Application approved and tenant record created!')),
                  );
                  // Refresh data
                  _loadData();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve & Convert'),
          ),
        ],
      ),
    );
  }
}