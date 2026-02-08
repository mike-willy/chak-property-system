import 'package:flutter/material.dart';
import '../../utils/receipt_generator.dart'; // Corrected import path
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/tenant_model.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/tenant_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tenant_provider.dart';




class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final tenantProvider = context.watch<TenantProvider>();
    final activeTenant = tenantProvider.tenant;
    
    // If no tenant is loaded, show empty/loading state
    if (tenantProvider.isLoading && activeTenant == null) {
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
        actions: [
          // Unit Switcher in AppBar if multiple units exist
          if (tenantProvider.userTenancies.length > 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Color(0xFF4E95FF)),
              tooltip: 'Switch Unit',
              onPressed: () => _showUnitSwitcher(context, tenantProvider),
            ),
        ],
      ),
      body: Column(
        children: [
          // Unit Indicator
          if (activeTenant != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              color: const Color(0xFF1E2235).withOpacity(0.5),
              child: Text(
                'Showing history for: ${activeTenant.propertyName} - Unit ${activeTenant.unitNumber}',
                style: const TextStyle(color: Color(0xFF4E95FF), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          
          _buildFilterBar(),
          Expanded(
            child: activeTenant == null 
              ? _buildEmptyState()
              : StreamBuilder<List<PaymentModel>>(
                  // Use ONLY the active tenant's ID
                  stream: context.read<PaymentRepository>().getPaymentsStream(activeTenant.id),
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
              'Select Unit for History',
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
              onPressed: () async {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Generating Receipt..."),
                    backgroundColor: Color(0xFF4E95FF),
                    duration: Duration(seconds: 1),
                  )
                );
                
                final tenantProvider = context.read<TenantProvider>();
                // Try to get tenant name, fallback to "Valued Tenant"
                final tenantName = tenantProvider.tenant?.fullName ?? "Valued Tenant";
                
                try {
                  await ReceiptGenerator.generateAndDownload(payment, tenantName: tenantName);
                } catch (e) {
                  debugPrint("Error generating receipt: $e");
                  if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to generate receipt: $e"),
                        backgroundColor: Colors.red,
                      )
                    );
                  }
                }
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
