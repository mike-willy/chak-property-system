// lib/presentation/screens/payments/payment_initiation.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/services/mpesa_service.dart';
import '../payment_status_page.dart';

class PaymentInitiation {
  final MpesaService _mpesaService = MpesaService();

  Future<void> initiatePayment({
    required BuildContext context,
    required String userId,
    required String phoneNumber,
    required double amount,
    required String reference,
  }) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4E95FF)),
        ),
      );

      print('Initiating payment for $phoneNumber amount $amount');

      // Step 1: Initiate STK Push
      final result = await _mpesaService.initiateStkPush(
        phoneNumber: phoneNumber,
        amount: amount,
        accountReference: reference,
        transactionDesc: 'Rent Payment',
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (result['success'] == true) {
        // Step 2: Save payment record to Firestore
        final paymentRef = await FirebaseFirestore.instance
            .collection('payments')
            .add({
          'tenantId': userId,
          'amount': amount,
          'phoneNumber': phoneNumber,
          'checkoutRequestId': result['checkoutRequestId'],
          'merchantRequestId': result['merchantRequestId'],
          'status': 'pending',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'initiatedAt': FieldValue.serverTimestamp(), // Added for consistency
          'reference': reference,
          'responseDescription': result['responseDescription'],
        });

        print('Payment record created: ${paymentRef.id}');

        // Step 3: Navigate to payment status page
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentStatusPage(
                paymentId: paymentRef.id,
                checkoutRequestId: result['checkoutRequestId'],
                amount: amount,
              ),
            ),
          );

          // Show initial success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['customerMessage'] ?? 'Check your phone to complete payment',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // STK Push failed
        throw Exception(result['error'] ?? 'Failed to initiate payment');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Payment initiation error: $e');
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}