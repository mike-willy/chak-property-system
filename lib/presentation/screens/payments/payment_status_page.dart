// lib/presentation/screens/payments/payment_status_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/services/mpesa_service.dart';
import 'dart:async';

class PaymentStatusPage extends StatefulWidget {
  final String paymentId;
  final String checkoutRequestId;
  final double amount;

  const PaymentStatusPage({
    Key? key,
    required this.paymentId,
    required this.checkoutRequestId,
    required this.amount,
  }) : super(key: key);

  @override
  State<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends State<PaymentStatusPage> {
  final _mpesaService = MpesaService();
  Timer? _statusCheckTimer;
  int _checkCount = 0;
  static const int _maxChecks = 20; // Check for 2 minutes (20 checks * 6 seconds)

  @override
  void initState() {
    super.initState();
    _startStatusChecking();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusChecking() {
    // Check status every 6 seconds
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 6),
      (timer) async {
        _checkCount++;
        
        if (_checkCount > _maxChecks) {
          timer.cancel();
          _updatePaymentStatus('timeout');
          return;
        }

        try {
          final result = await _mpesaService.queryTransactionStatus(
            checkoutRequestId: widget.checkoutRequestId,
          );

          final resultCode = result['ResultCode']?.toString() ?? '';
          
          if (resultCode == '0') {
            // Success
            timer.cancel();
            _updatePaymentStatus('completed');
          } else if (resultCode == '1032') {
            // User cancelled
            timer.cancel();
            _updatePaymentStatus('cancelled');
          } else if (resultCode.isNotEmpty && resultCode != '0') {
            // Failed
            timer.cancel();
            _updatePaymentStatus('failed', result['ResultDesc']);
          }
        } catch (e) {
          print('Error checking status: $e');
          // Continue checking
        }
      },
    );
  }

  Future<void> _updatePaymentStatus(String status, [String? description]) async {
    try {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(widget.paymentId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (description != null) 'statusDescription': description,
      });
    } catch (e) {
      print('Error updating payment status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141725),
      appBar: AppBar(
        title: const Text('Payment Status', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF141725),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .doc(widget.paymentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildLoadingState();
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return _buildErrorState('Payment not found');
          }

          final status = data['status'] ?? 'pending';
          
          return _buildStatusContent(status, data);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF4E95FF)),
          const SizedBox(height: 24),
          Text(
            'Loading payment status...',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent(String status, Map<String, dynamic> data) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return _buildSuccessState(data);
      case 'failed':
        return _buildFailedState(data);
      case 'cancelled':
        return _buildCancelledState();
      case 'timeout':
        return _buildTimeoutState();
      default:
        return _buildPendingState();
    }
  }

  Widget _buildPendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_android,
                size: 64,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Check Your Phone',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please enter your M-Pesa PIN on your phone to complete the payment',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2235),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      Text(
                        'KES ${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFF4E95FF)),
            const SizedBox(height: 16),
            Text(
              'Waiting for confirmation...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(Map<String, dynamic> data) {
    _statusCheckTimer?.cancel(); // Stop checking
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your rent payment has been processed',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2235),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Amount', 'KES ${widget.amount.toStringAsFixed(2)}'),
                  if (data['mpesaReceiptNumber'] != null) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 12),
                    _buildDetailRow('Receipt No.', data['mpesaReceiptNumber']),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E95FF),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedState(Map<String, dynamic> data) {
    _statusCheckTimer?.cancel();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Payment Failed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data['statusDescription'] ?? 'The payment could not be processed',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E95FF),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledState() {
    _statusCheckTimer?.cancel();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel,
                size: 64,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Payment Cancelled',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You cancelled the payment request',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E95FF),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutState() {
    _statusCheckTimer?.cancel();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_off,
                size: 64,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Payment Timeout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The payment request timed out. Please try again.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E95FF),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade400),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}