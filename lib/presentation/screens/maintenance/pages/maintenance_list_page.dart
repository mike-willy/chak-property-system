// presentation/screens/maintenance/pages/maintenance_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../providers/maintenance_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../data/models/maintenance_model.dart';
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
      backgroundColor: Colors.white,
      body: Consumer2<MaintenanceProvider, AuthProvider>(
        builder: (context, provider, authProvider, _) {
          return Column(
            children: [
              // Header Section
              _buildHeaderSection(provider, authProvider),
              
              // Filter Section
              _buildFilterSection(provider),
              
              // Requests List
              Expanded(
                child: _buildRequestsList(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isTenant) {
            return FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateMaintenanceRequestPage(),
                  ),
                ).then((_) {
                  // Reload requests after creating
                  _loadRequests();
                });
              },
              icon: const Icon(FontAwesomeIcons.plus),
              label: const Text('New Request'),
              backgroundColor: Colors.blue,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeaderSection(MaintenanceProvider provider, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade700,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            authProvider.isTenant ? 'My Maintenance Requests' : 'Maintenance Requests',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            authProvider.isTenant
                ? 'Track your maintenance requests'
                : 'Manage all maintenance requests',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterSection(MaintenanceProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'All',
              value: 'all',
              provider: provider,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Open',
              value: 'open',
              icon: FontAwesomeIcons.circleExclamation,
              provider: provider,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'In Progress',
              value: 'in-progress',
              icon: FontAwesomeIcons.hammer,
              provider: provider,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Completed',
              value: 'completed',
              icon: FontAwesomeIcons.circleCheck,
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => provider.setFilterStatus(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
                  color: Colors.grey.shade700,
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
                icon: const Icon(FontAwesomeIcons.rotate),
                label: const Text('Retry'),
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
            CircularProgressIndicator(),
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
                    Icon(
                      FontAwesomeIcons.tools,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No maintenance requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.filterStatus != 'all'
                          ? 'Try changing your filter'
                          : 'Submit your first maintenance request',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
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
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Extra padding for FAB
        itemCount: provider.filteredRequests.length,
        itemBuilder: (context, index) {
          final request = provider.filteredRequests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
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

