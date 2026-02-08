import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../data/models/payment_model.dart';
import '../../../../data/models/tenant_model.dart';
import '../../../../providers/tenant_provider.dart';
import '../../../../providers/property_provider.dart';

import '../../../utils/receipt_generator.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../data/repositories/payment_repository.dart';

class LandlordPaymentHistoryPage extends StatefulWidget {
  const LandlordPaymentHistoryPage({super.key});

  @override
  State<LandlordPaymentHistoryPage> createState() => _LandlordPaymentHistoryPageState();
}

class _LandlordPaymentHistoryPageState extends State<LandlordPaymentHistoryPage> {

  bool _isLoading = true;
  String? _error;



  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final propertyProvider = context.read<PropertyProvider>();
      final tenantProvider = context.read<TenantProvider>();
      // final paymentRepository = context.read<PaymentRepository>(); // For potential future use
      
      // 1. Ensure properties are loaded (if not already)
      if (propertyProvider.properties.isEmpty) {
         await propertyProvider.loadProperties();
      }

      // 2. Identify Landlord's Properties (STRICT FILTER)
      // Fix: Ensure we only get properties where ownerId matches current user
      final userId = context.read<AuthProvider>().userId;
      final properties = propertyProvider.properties
          .where((p) => userId != null && p.ownerId == userId)
          .toList();

      final propertyIds = properties.map((p) => p.id).toList();
      
      debugPrint('LANDLORD_HISTORY: Found ${properties.length} properties for user $userId');

      // 3. Load Tenants specific to these properties
      if (propertyIds.isNotEmpty) {
        await tenantProvider.loadLandlordTenants(propertyIds);
      }



      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false; 
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access providers
    final tenantProvider = context.watch<TenantProvider>();
    final tenants = tenantProvider.tenantsList; 

    return Scaffold(
      backgroundColor: const Color(0xFF141725),
      appBar: AppBar(
        title: const Text('Payment History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141725),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4E95FF)))
        : _error != null
          ? _buildErrorState(_error!)
          : StreamBuilder<List<PaymentModel>>(
              stream: context.read<PaymentRepository>().getAllPaymentsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF4E95FF)));
                }

                // STRICT FILTERING: 
                // Only show completed payments where the tenantId belongs to one of "My Tenants"
                final myTenantIds = tenants.map((t) => t.id).toSet();
                
                final payments = (snapshot.data ?? [])
                    .where((p) => 
                        p.status == PaymentStatus.completed && 
                        myTenantIds.contains(p.tenantId)
                    )
                    .toList();
                
                return Column(
                  children: [
                    // Revenue Card (Calculated from filtered data)
                    _buildRevenueCard(tenants, payments),
                    
                    // Payment List
                    Expanded(
                      child: payments.isEmpty
                          ? _buildEmptyState("No payments found for your properties.")
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: payments.length,
                              itemBuilder: (context, index) {
                                final payment = payments[index];
                                // Find tenant details for display
                                final tenant = tenants.firstWhere(
                                  (t) => t.id == payment.tenantId, 
                                  orElse: () => TenantModel(
                                    id: 'unknown', 
                                    userId: 'unknown', 
                                    unitId: 'unknown', 
                                    fullName: 'Unknown Tenant', 
                                    email: '', 
                                    phone: '', 
                                    propertyId: 'unknown',
                                    propertyName: 'Unknown Property',
                                    unitNumber: '?',
                                    rentAmount: 0,
                                    leaseStartDate: DateTime.now(),
                                    leaseEndDate: DateTime.now(),
                                    status: TenantStatus.active,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now()
                                  )
                                );
                                
                                return _buildLandlordTransactionCard(payment, tenant);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildRevenueCard(List<TenantModel> tenants, List<PaymentModel> payments) {


    // Calculate Collected Revenue (Sum of completed payments in current month)
    final now = DateTime.now();
    final collectedRevenue = payments
        .where((p) {
            // FIX: Use dueDate if paidDate is missing.
            final date = p.paidDate ?? p.dueDate;
            return date.month == now.month && date.year == now.year;
        })
        .fold(0.0, (sum, p) => sum + p.amount);



    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'This Month',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4E95FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(color: Color(0xFF4E95FF), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          Center(
            child: _buildRevenueItem(
              'Collected', 
              collectedRevenue, 
              Colors.green.shade300,
              FontAwesomeIcons.check
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(String label, double amount, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.7)),
        const SizedBox(height: 8),
        Text(
          NumberFormat('#,##0').format(amount),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
      ],
    );
  }



  Widget _buildLandlordTransactionCard(PaymentModel payment, TenantModel tenant) {
    final isSuccess = payment.status == PaymentStatus.completed;
    final date = payment.paidDate ?? payment.dueDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSuccess 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSuccess ? Icons.check : Icons.access_time,
                        color: isSuccess ? Colors.green : Colors.orange,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenant.propertyName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Unit ${tenant.unitNumber} • ${tenant.fullName}',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'KES ${NumberFormat('#,###').format(payment.amount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, hh:mm a').format(date),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          if (isSuccess && (payment.transactionId?.isNotEmpty ?? false)) ...[
             const SizedBox(height: 12),
             Divider(color: Colors.white.withOpacity(0.05), height: 1),
             const SizedBox(height: 12),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  Expanded(
                    child: Text(
                      'Ref: ${payment.transactionId}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontFamily: 'Monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                 // Receipt Button Removed
               ],
             )
          ]
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.receipt, size: 48, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(child: Text("Error: $error", style: const TextStyle(color: Colors.red)));
  }
}
