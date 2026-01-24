import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../providers/property_provider.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/models/tenant_model.dart'; // Added
import '../../../../data/models/maintenance_model.dart'; // Added for MaintenanceStatus
import '../../../../providers/tenant_provider.dart';
import '../../../../providers/maintenance_provider.dart';
import '../../../../data/models/payment_model.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFF141725),
      body: SafeArea(
        child: Consumer3<PropertyProvider, TenantProvider, MaintenanceProvider>(
          builder: (context, propertyProvider, tenantProvider, maintenanceProvider, _) {
            // 1. Calculate Metrics
            final properties = propertyProvider.properties; // Already filtered for landlord
            final tenants = tenantProvider.tenantsList; // Already filtered for landlord
            final requests = maintenanceProvider.requests; // Already filtered for landlord

            // Property Stats
            final totalProperties = properties.length;
            // Calculate strictly from the local list to ensure accuracy
            final occupiedCount = properties.where((p) => p.status == PropertyStatus.occupied).length;
            final vacantCount = properties.where((p) => p.status == PropertyStatus.vacant).length;
            
            final occupancyRate = (totalProperties > 0) 
                ? (occupiedCount / totalProperties * 100).toStringAsFixed(1) 
                : '0.0';

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
                            'Analytics & Reports',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Overview of your portfolio performance',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _loadRevenueData,
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 1. Financial Overview
                  _buildSectionTitle('Financials'),
                  _buildFinancialCard(tenants), 

                  const SizedBox(height: 24),

                  // 2. Occupancy
                  _buildSectionTitle('Occupancy'),
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
                          'Vacant Properties',
                          vacantCount.toString(),
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
