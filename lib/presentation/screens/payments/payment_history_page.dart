import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class PaymentHistoryPage extends StatefulWidget {
  // Added 'const' here - this fixes the "Not a constant expression" error
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  String _filterStatus = 'completed'; 

  @override
  Widget build(BuildContext context) {
    // Using watch instead of read for reactive updates if the ID changes
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF141725),
      appBar: AppBar(
        title: const Text('Payment History', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141725),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('payments')
                  .where('tenantId', isEqualTo: authProvider.userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint("Firestore Error: ${snapshot.error}");
                  return _buildErrorState(snapshot.error.toString());
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF4E95FF)));
                }

                final allDocs = snapshot.data?.docs ?? [];
                
                // Filtering
                final docs = _filterStatus == 'all' 
                    ? allDocs 
                    : allDocs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return data['status'] == 'completed';
                      }).toList();

                if (docs.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildTransactionCard(data);
                  },
                );
              },
            ),
          ),
        ],
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

  Widget _buildTransactionCard(Map<String, dynamic> data) {
    final String status = (data['status'] ?? 'pending').toString().toLowerCase();
    final double amount = (data['amount'] ?? 0).toDouble();
    final DateTime? date = (data['createdAt'] as Timestamp?)?.toDate();
    final bool isSuccess = status == 'completed';

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
          'KES ${NumberFormat('#,###').format(amount)}', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              date != null ? DateFormat('MMMM dd, yyyy • hh:mm a').format(date) : 'Date Unknown',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        trailing: isSuccess 
          ? IconButton(
              icon: const Icon(Icons.file_download_outlined, color: Color(0xFF4E95FF)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Generating PDF for KES $amount..."),
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