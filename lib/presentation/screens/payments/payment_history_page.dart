import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for local query
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/tenant_model.dart'; // Added
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/tenant_repository.dart'; // Added
import '../../../providers/auth_provider.dart';
import '../../../providers/tenant_provider.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  String _filterStatus = 'all';

  // Helper to fetch all tenant IDs for the user directly
  Future<List<String>> _fetchTenantIds(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tenants')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error fetching tenant IDs: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get AuthProvider for User ID
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.userId; 

    // 2. Fetch ALL Tenant IDs for this user (using local helper)
    return FutureBuilder<List<String>>(
      future: userId != null 
          ? _fetchTenantIds(userId)
          : Future.value([]),
      builder: (context, snapshot) {
        // Collect IDs
        final allTenantIds = snapshot.data ?? [];
        
        // Add current tenant ID from provider if not in list
        final providerTenant = context.watch<TenantProvider>().tenant;
        if (providerTenant != null && !allTenantIds.contains(providerTenant.id)) {
          allTenantIds.add(providerTenant.id);
        }

        // Combine with User ID
        final idsToQuery = <String>{
          if (userId != null) userId,
          ...allTenantIds
        }.toList();

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting && idsToQuery.isEmpty) {
           return Scaffold(
            backgroundColor: const Color(0xFF141725),
            appBar: AppBar(title: const Text('Payment History'), backgroundColor: const Color(0xFF141725)),
            body: const Center(child: CircularProgressIndicator(color: Color(0xFF4E95FF))),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF141725),
          appBar: AppBar(
            title: const Text('Payment History',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF141725),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: StreamBuilder<List<PaymentModel>>(
                  // Use List of ALL IDs
                  stream: context.read<PaymentRepository>().getPaymentsStreamForList(idsToQuery),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint("Payment Stream Error: ${snapshot.error}");
                      return _buildErrorState(snapshot.error.toString());
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF4E95FF)));
                    }

                    final allPayments = snapshot.data ?? [];

                    // Filtering
                    final payments = _filterStatus == 'all'
                        ? allPayments
                        : allPayments.where((p) => p.status.value == 'completed').toList();

                    if (payments.isEmpty) return _buildEmptyState();

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(payments[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          _filterChip('Official Receipts', 'completed'),
          const SizedBox(width: 8),
          _filterChip('All Attempts', 'all'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    bool isSelected = _filterStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) setState(() => _filterStatus = value);
      },
      selectedColor: const Color(0xFF4E95FF),
      backgroundColor: const Color(0xFF1E2235),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTransactionCard(PaymentModel payment) {
    final status = payment.status.value;
    final isSuccess = status == 'completed';
    // Use paidDate if available (completed), otherwise user init date (dueDate in model maps to initiatedAt)
    final date = payment.paidDate ?? payment.dueDate;

    return Card(
      color: const Color(0xFF1E2235),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSuccess ? Icons.receipt_long : Icons.pending_actions,
            color: isSuccess ? Colors.greenAccent : Colors.orangeAccent,
          ),
        ),
        title: Text(
          'KES ${NumberFormat('#,###').format(payment.amount)}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('MMMM dd, yyyy • hh:mm a').format(date),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
             if (payment.transactionId != null && payment.transactionId!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Ref: ${payment.transactionId}',
                   style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ),
          ],
        ),
        trailing: isSuccess
          ? IconButton(
              icon: const Icon(Icons.file_download_outlined, color: Color(0xFF4E95FF)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Generating Receipt for KES ${payment.amount}..."),
                    backgroundColor: const Color(0xFF4E95FF),
                  )
                );
              },
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.toUpperCase(),
                style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)
              ),
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text("No payment history found",
            style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          "Error: $error",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent)
        ),
      ),
    );
  }
}
