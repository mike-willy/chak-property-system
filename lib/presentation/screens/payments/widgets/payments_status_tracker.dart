
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentStatusTracker extends StatelessWidget {
  final String paymentId;
  
  const PaymentStatusTracker({
    super.key,
    required this.paymentId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4E95FF)),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return _buildErrorState('Payment not found');
        }

        final status = data['status'] ?? 'pending';
        
        return _buildStatusCard(status, data);
      },
    );
  }

  Widget _buildStatusCard(String status, Map<String, dynamic> data) {
    Color statusColor;
    IconData statusIcon;
    String statusMessage;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusMessage = 'Payment Successful';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusMessage = 'Payment Failed';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusMessage = 'Payment Pending';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 48),
          const SizedBox(height: 16),
          Text(
            statusMessage,
            style: TextStyle(
              color: statusColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Amount: KES ${data['amount'] ?? 0}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          if (data['mpesaReceiptNumber'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Receipt: ${data['mpesaReceiptNumber']}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
          if (status.toLowerCase() == 'pending') ...[
            const SizedBox(height: 16),
            const Text(
              'Please check your phone and enter your M-Pesa PIN',
              style: TextStyle(color: Colors.orange, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// Usage in payment_page.dart after STK push:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => PaymentStatusPage(paymentId: paymentId),
//   ),
// );