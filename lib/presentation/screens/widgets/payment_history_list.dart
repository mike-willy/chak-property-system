import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/payment_model.dart';

class PaymentHistoryList extends StatelessWidget {
  final List<PaymentModel> payments;
  final bool isLoading;
  final VoidCallback onViewAll;

  const PaymentHistoryList({
    super.key,
    required this.payments,
    required this.isLoading,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "No recent payments found.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Sort to ensure latest are first (redundant if backend/repo already sorts)
    final sortedPayments = List<PaymentModel>.from(payments);
    sortedPayments.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    
    // Limit to latest 3 for dashboard
    final limitedPayments = sortedPayments.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Payments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All', style: TextStyle(color: Color(0xFF4E95FF))),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...limitedPayments.map((payment) => _buildPaymentItem(payment)),
      ],
    );
  }

  Widget _buildPaymentItem(PaymentModel payment) {
    final currency = NumberFormat.currency(symbol: '\$'); // Using $ as per previous screenshots/code, or KES? sticking to consistency
    final dateFormat = DateFormat('MMM d, yyyy');
    
    String title = payment.method == PaymentMethod.mobile ? 'MPESA Payment' : 'Payment';
    Color statusColor = payment.status == PaymentStatus.completed ? Colors.greenAccent : (payment.status == PaymentStatus.failed ? Colors.redAccent : Colors.orangeAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              payment.status == PaymentStatus.completed ? Icons.check : (payment.status == PaymentStatus.failed ? Icons.error_outline : Icons.access_time), 
              color: statusColor, 
              size: 18
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(payment.dueDate),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(payment.amount),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                payment.status.value.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }
}
