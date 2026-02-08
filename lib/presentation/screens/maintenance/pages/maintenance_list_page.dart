// presentation/screens/maintenance/pages/maintenance_list_page.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../providers/maintenance_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/tenant_provider.dart';
import '../widgets/maintenance_card.dart';
import 'create_maintenance_request_page.dart';
import 'maintenance_detail_page.dart';

class MaintenanceListPage extends StatefulWidget {
  const MaintenanceListPage({super.key});

  @override
  State<MaintenanceListPage> createState() => _MaintenanceListPageState();
}

class _MaintenanceListPageState extends State<MaintenanceListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  void _loadRequests() {
    final provider = context.read<MaintenanceProvider>();
    if (provider.requests.isEmpty || provider.error != null) {
      provider.loadRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141725), // Dark Dashboard Background
      body: Consumer3<MaintenanceProvider, AuthProvider, TenantProvider>(
        builder: (context, provider, authProvider, tenantProvider, _) {
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(provider, authProvider, tenantProvider),
                
                // Unit Indicator for Tenants
                if (authProvider.isTenant && tenantProvider.tenant != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    width: double.infinity,
                    color: const Color(0xFF1E2235).withOpacity(0.5),
                    child: Text(
                      'Showing requests for: ${tenantProvider.tenant!.propertyName} - Unit ${tenantProvider.tenant!.unitNumber}',
                      style: const TextStyle(color: Color(0xFF4E95FF), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),

                // Filter Section
                _buildFilterSection(provider),
                
                // Requests List
                Expanded(
                  child: _buildRequestsList(provider),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isTenant) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateMaintenanceRequestPage(),
                  ),
                ).then((_) {
                  _loadRequests();
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10, right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4E95FF), Color(0xFF1E60E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4E95FF).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FontAwesomeIcons.plus, color: Colors.white, size: 16),
                    SizedBox(width: 10),
                    Text(
                      'New Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeaderSection(MaintenanceProvider provider, AuthProvider authProvider, TenantProvider tenantProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      authProvider.isTenant ? 'Maintenance' : 'Requests',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.isTenant
                          ? 'Track and manage your requests'
                          : 'Manage all maintenance requests',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Row(
                children: [
                  if (authProvider.isTenant)
                    IconButton(
                      onPressed: () => _showUnitSwitcher(context, tenantProvider),
                      icon: const Icon(Icons.swap_horiz, color: Color(0xFF4E95FF)),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2235),
                        padding: const EdgeInsets.all(12),
                      ),
                      tooltip: 'Switch Unit',
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: provider.loadRequests,
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    style: IconButton.styleFrom(
                       backgroundColor: const Color(0xFF1E2235),
                       padding: const EdgeInsets.all(12),
                    ),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUnitSwitcher(BuildContext context, TenantProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141725),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Unit for Maintenance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            ...provider.userTenancies.map((t) => ListTile(
              leading: Icon(
                Icons.home, 
                color: t.id == provider.tenant?.id ? const Color(0xFF4E95FF) : Colors.grey
              ),
              title: Text(
                t.propertyName,
                style: TextStyle(
                  color: t.id == provider.tenant?.id ? Colors.white : Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('Unit ${t.unitNumber}', style: TextStyle(color: Colors.grey.shade500)),
              trailing: t.id == provider.tenant?.id 
                  ? const Icon(Icons.check_circle, color: Color(0xFF4E95FF))
                  : null,
              onTap: () {
                provider.switchTenant(t);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(MaintenanceProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'All',
              value: 'all',
              provider: provider,
            ),
            const SizedBox(width: 10),
            _buildFilterChip(
              label: 'Pending', // Changed label to Pending as well to be accurate
              value: 'pending',
              icon: FontAwesomeIcons.circleExclamation,
              provider: provider,
            ),
            const SizedBox(width: 10),
            _buildFilterChip(
              label: 'In Progress',
              value: 'in-progress',
              icon: FontAwesomeIcons.hammer,
              provider: provider,
            ),
            const SizedBox(width: 10),
            _buildFilterChip(
              label: 'Completed',
              value: 'completed',
              icon: FontAwesomeIcons.circleCheck,
              provider: provider,
            ),
            const SizedBox(width: 10),
            _buildFilterChip(
              label: 'On Hold',
              value: 'on-hold',
              icon: FontAwesomeIcons.circlePause,
              provider: provider,
            ),
            const SizedBox(width: 10),
            _buildFilterChip(
              label: 'Cancelled',
              value: 'cancelled',
              icon: FontAwesomeIcons.circleXmark,
              provider: provider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    IconData? icon,
    required MaintenanceProvider provider,
  }) {
    final isSelected = provider.filterStatus == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => provider.setFilterStatus(value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4E95FF) : const Color(0xFF1E2235), // Dark Chip
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF4E95FF) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(MaintenanceProvider provider) {
    debugPrint('MaintenanceListPage: filteredRequests.length = ${provider.filteredRequests.length}');
    debugPrint('MaintenanceListPage: isLoading = ${provider.isLoading}');
    debugPrint('MaintenanceListPage: error = ${provider.error}');

    // Show error if there's an error and no requests
    if (provider.error != null && provider.requests.isEmpty && !provider.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.exclamationTriangle,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  provider.clearError();
                  provider.loadRequests();
                },
                icon: const Icon(FontAwesomeIcons.rotate, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4E95FF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.isLoading && provider.requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4E95FF)),
            SizedBox(height: 16),
            Text(
              'Loading maintenance requests...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (provider.filteredRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.loadRequests(),
        backgroundColor: const Color(0xFF1E2235),
        color: const Color(0xFF4E95FF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2235),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        FontAwesomeIcons.tools,
                        size: 48,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No maintenance requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.filterStatus != 'all'
                          ? 'Try changing your filter'
                          : 'Submit your first maintenance request',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadRequests(),
      backgroundColor: const Color(0xFF1E2235),
       color: const Color(0xFF4E95FF),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // Extra padding for FAB
        itemCount: provider.filteredRequests.length,
        itemBuilder: (context, index) {
          final request = provider.filteredRequests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: MaintenanceCard(
              request: request,
              onView: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MaintenanceDetailPage(request: request),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

