import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../data/repositories/tenant_repository.dart';
import '../../../data/models/tenant_model.dart';
import '../widgets/header_section.dart';
import '../widgets/upcoming_rent_card.dart';
import '../widgets/status_row.dart';
import '../widgets/recent_activity.dart';
import '../widgets/cta_section.dart';
import '../../../core/common/constants.dart';
import '../properties/pages/property_list_page.dart';
import 'messages_page.dart';
import 'maintenance_page.dart';
import 'profile_page.dart';
import '../../../data/models/user_model.dart';


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
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Rentals'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Maint.'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
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
  TenantModel? _tenantData;
  bool _isLoadingTenant = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load properties
      final propertyProvider = context.read<PropertyProvider>();
      if (propertyProvider.properties.isEmpty) {
        propertyProvider.loadProperties();
      }

      // Load tenant data for tenants
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isTenant && authProvider.firebaseUser != null) {
        _loadTenantData(authProvider.firebaseUser!.uid);
      }
    });
  }

  Future<void> _loadTenantData(String userId) async {
    setState(() {
      _isLoadingTenant = true;
    });
    try {
      final tenantRepo = TenantRepository();
      _tenantData = await tenantRepo.getTenantByUserId(userId);
    } catch (e) {
      debugPrint('Error loading tenant data: $e');
    } finally {
      setState(() {
        _isLoadingTenant = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.horizontalPadding),
        child: Consumer2<AuthProvider, PropertyProvider>(
          builder: (context, authProvider, propertyProvider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with user data
                HeaderSection(
                  userName: authProvider.userProfile?.name ?? 'User',
                  userRole: authProvider.userProfile?.role.value ?? 'Unknown',
                ),
                const SizedBox(height: 24),

                // Upcoming Rent Card - for tenants
                if (authProvider.isTenant)
                  UpcomingRentCard(
                    tenantData: _tenantData,
                    isLoading: _isLoadingTenant,
                    properties: propertyProvider.properties,
                  )
                else
                  const SizedBox.shrink(), // Hide for non-tenants

                const SizedBox(height: 24),

                // Status Row - show property stats
                // StatusRow(
                //   properties: propertyProvider.properties,
                //   isLoading: propertyProvider.isLoading,
                //   error: propertyProvider.error,
                // ),

                const SizedBox(height: 32),

                // Recent Activity - show recent properties or maintenance
               RecentActivity(
  properties: propertyProvider.filteredProperties.take(3).toList(), // Show last 3 properties
  isLoading: propertyProvider.isLoading,
),

                const SizedBox(height: 32),

                // CTA Section - static
                const CTASection(),
              ],
            );
          },
        ),
      ),
    );
  }
}

