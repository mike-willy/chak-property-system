import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../providers/property_provider.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/models/tenant_model.dart'; // Added
import '../../../../data/models/maintenance_model.dart'; // Added for MaintenanceStatus
import '../../../../providers/tenant_provider.dart';
import '../../../../providers/maintenance_provider.dart';
import '../../../../presentation/themes/theme_colors.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  double _totalCollectedRevenue = 0.0;
  bool _isLoadingRevenue = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRevenueData();
      context.read<PropertyProvider>().loadStats();
    });
  }

  Future<void> _loadRevenueData() async {
    final tenantProvider = context.read<TenantProvider>();
    setState(() => _isLoadingRevenue = true);
    
    final total = await tenantProvider.calculateTotalCollectedRevenue();
    
    if (mounted) {
      setState(() {
        _totalCollectedRevenue = total;
        _isLoadingRevenue = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF141725),
      child: Consumer4<AuthProvider, PropertyProvider, TenantProvider, MaintenanceProvider>(
        builder: (context, authProvider, propertyProvider, tenantProvider, maintenanceProvider, _) {
          // 1. Calculate Metrics with STRICT Filtering & Unit-Based Stats
          final userId = authProvider.userId;
          if (userId == null) {
             return const Center(child: CircularProgressIndicator());
          }

          // Trigger stats load if empty (or handled in initState/provider update)
          if (propertyProvider.stats.isEmpty && !propertyProvider.isLoading) {
             // propertyProvider.loadStats(); // Be careful of infinite rebuilds here
          }

          final stats = propertyProvider.stats;
          final totalUnits = stats['total'] as int? ?? 0;
          final vacantUnits = stats['vacant'] as int? ?? 0;
          final occupiedUnits = stats['occupied'] as int? ?? 0;
          // final maintenanceUnits = stats['maintenance'] as int? ?? 0;
          
          final occupancyRate = (totalUnits > 0) 
              ? (occupiedUnits / totalUnits * 100).toStringAsFixed(1) 
              : '0.0';

          // Filter Tenants & Requests (Keep strict filtering for these lists)
          final properties = propertyProvider.properties
              .where((p) => p.ownerId == userId)
              .toList(); 
          final myPropertyIds = properties.map((p) => p.id).toSet();
          
          final tenants = tenantProvider.tenantsList
              .where((t) => myPropertyIds.contains(t.propertyId))
              .toList(); 

          final requests = maintenanceProvider.requests
              .where((r) => myPropertyIds.contains(r.propertyId))
              .toList();

          // Maintenance Stats
          final openRequests = requests.where((r) => r.status == MaintenanceStatus.open || r.status == MaintenanceStatus.inProgress).length;
          final completedRequests = requests.where((r) => r.status == MaintenanceStatus.completed).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Overview',
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Portfolio performance (Units)',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        _loadRevenueData();
                        propertyProvider.loadStats(); // Refresh stats on button press
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 1. Financial Overview
                _buildSectionTitle('Financials'),
                _buildFinancialCard(tenants), 

                const SizedBox(height: 24),

                // 2. Portfolio Overview
                _buildSectionTitle('Portfolio Overview'),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Properties',
                        properties.length.toString(),
                        Icons.apartment,
                        Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Total Units',
                        totalUnits.toString(),
                        Icons.meeting_room_outlined,
                        Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Occupancy Rate', 
                        '$occupancyRate%', 
                        Icons.pie_chart,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Vacant Units', 
                        vacantUnits.toString(),
                        Icons.home_outlined, 
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Maintenance
                _buildSectionTitle('Maintenance Health'),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Open Requests',
                        openRequests.toString(),
                        Icons.build_circle_outlined,
                        Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Completed',
                        completedRequests.toString(),
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(List<dynamic> tenants) {
    // Projected Revenue
    double projectedRevenue = 0;
    for (var t in tenants) {
      if (t is TenantModel && t.status == TenantStatus.active) { 
        projectedRevenue += (t.rentAmount); 
      }
    }

    final currency = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(FontAwesomeIcons.moneyBillWave, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Revenue Collected',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _isLoadingRevenue 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : Text(
                          currency.format(_totalCollectedRevenue),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Divider
          Divider(color: Colors.white.withOpacity(0.2)),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Projected Monthly', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    currency.format(projectedRevenue),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${tenants.length} Active Tenants',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
