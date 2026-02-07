// lib/presentation/screens/payments/payment_status_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/services/mpesa_service.dart';
import '../../../core/services/notification_service.dart' as service;
import 'dart:async';

class PaymentStatusPage extends StatefulWidget {
  final String paymentId;
  final String checkoutRequestId;
  final double amount;

  const PaymentStatusPage({
    super.key,
    required this.paymentId,
    required this.checkoutRequestId,
    required this.amount,
  });

  @override
  State<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends State<PaymentStatusPage> {
  final _mpesaService = MpesaService();
  Timer? _statusCheckTimer;
  int _checkCount = 0;
  static const int _maxChecks = 25; // Check for ~2.5 minutes (25 checks * 6 seconds)

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
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 6),
      (timer) async {
        _checkCount++;
        
        if (_checkCount > _maxChecks) {
          timer.cancel();
          _localFirestoreUpdate('timeout');
          return;
        }

        try {
          final result = await _mpesaService.queryTransactionStatus(
            checkoutRequestId: widget.checkoutRequestId,
          );

          final resultCode = result['ResultCode']?.toString() ?? '';
          
          if (resultCode == '0') {
            // Success: We stop polling and wait for the Server Callback to update Firestore
            timer.cancel();
          } else if (resultCode == '1032') {
            // User cancelled on their phone
            timer.cancel();
            _localFirestoreUpdate('cancelled');
          } else if (resultCode.isNotEmpty && resultCode != '0') {
            // Failed for other reasons (insufficient funds, etc)
            timer.cancel();
            _localFirestoreUpdate('failed', result['ResultDesc']);
          }
        } catch (e) {
          debugPrint('Status query error: $e');
        }
      },
    );
  }

  Future<void> _localFirestoreUpdate(String status, [String? description]) async {
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
      debugPrint('Firestore update error: $e');
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
        automaticallyImplyLeading: false, // Prevent users from going back during PIN entry
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .doc(widget.paymentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _buildErrorState('Connection error');
          if (!snapshot.hasData) return _buildLoadingState();

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return _buildErrorState('Payment record not found');

          final status = (data['status'] ?? 'pending').toString().toLowerCase();
          
          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: _buildStatusContent(status, data),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusContent(String status, Map<String, dynamic> data) {
    switch (status) {
      case 'completed':
      case 'success':
        _statusCheckTimer?.cancel();
        // Send notification
        if (data['tenantId'] != null) {
          service.NotificationService.sendPaymentNotification(
            userId: data['tenantId'],
            propertyName: 'Rent Payment', // We could fetch property name from reference if needed
            amount: widget.amount,
            paymentType: 'Monthly Rent',
          );
        }
        return _buildSuccessState(data);
      case 'failed':
        _statusCheckTimer?.cancel();
        return _buildFailedState(data);
      case 'cancelled':
        _statusCheckTimer?.cancel();
        return _buildCancelledState();
      case 'timeout':
        _statusCheckTimer?.cancel();
        return _buildTimeoutState();
      default:
        return _buildPendingState();
    }
  }

  Widget _buildPendingState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.phone_android, size: 64, color: Colors.orange),
        ),
        const SizedBox(height: 32),
        const Text(
          'Check Your Phone',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Please enter your M-Pesa PIN on your phone to complete the payment',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        _buildInfoCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount', style: TextStyle(color: Colors.grey.shade400)),
              Text(
                'KES ${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        const CircularProgressIndicator(color: Color(0xFF4E95FF)),
        const SizedBox(height: 24),
        Text(
          'Waiting for confirmation...',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSuccessState(Map<String, dynamic> data) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, size: 64, color: Colors.green),
        ),
        const SizedBox(height: 32),
        const Text(
          'Payment Successful!',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Your rent payment has been processed successfully.',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        _buildInfoCard(
          child: Column(
            children: [
              _buildDetailRow('Amount', 'KES ${widget.amount.toStringAsFixed(2)}'),
              if (data['mpesaReceiptNumber'] != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white10),
                ),
                _buildDetailRow('Receipt No.', data['mpesaReceiptNumber']),
              ],
            ],
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4E95FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildFailedState(Map<String, dynamic> data) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
        const SizedBox(height: 24),
        const Text('Payment Failed', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
          data['statusDescription'] ?? 'Transaction could not be completed',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        _buildActionButton('Try Again', () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildCancelledState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.cancel_outlined, size: 80, color: Colors.orangeAccent),
        const SizedBox(height: 24),
        const Text('Cancelled', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('You cancelled the payment request.', style: TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        _buildActionButton('Go Back', () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildTimeoutState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.timer_off_outlined, size: 80, color: Colors.grey),
        const SizedBox(height: 24),
        const Text('Timed Out', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('The request took too long. Check your phone or try again.', style: TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        _buildActionButton('Try Again', () => Navigator.pop(context)),
      ],
    );
  }

  // --- UI Helpers ---

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4E95FF),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade400)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: Color(0xFF4E95FF)));
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white)),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
        ],
      ),
    );
  }
}