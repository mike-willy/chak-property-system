import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/mpesa_service.dart';

class PaymentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MpesaService _mpesaService = MpesaService();

  CollectionReference get _paymentsRef => _db.collection('payments');

  Future<void> initiatePayment({
    required String applicationId,
    required String tenantId,
    required String phoneNumber,
    required double amount,
    required String propertyName,
  }) async {
    try {
      // 1. Initiate STK Push
      // Format phone number (remove leading 0 or +, ensure 254)
      String formattedPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '254${formattedPhone.substring(1)}';
      }

      print('Initiating payment for $phoneNumber ($formattedPhone) amount $amount');

      final result = await _mpesaService.initiateStkPush(
        phoneNumber: formattedPhone,
        amount: amount,
        accountReference: applicationId.substring(0, Math.min(12, applicationId.length)), // Max 12 chars
        transactionDesc: 'Rent Payment',
      );

      final checkoutRequestId = result['CheckoutRequestID'];
      final responseCode = result['ResponseCode'];

      // 2. Create Payment Record (Pending)
      await _paymentsRef.add({
        'applicationId': applicationId,
        'tenantId': tenantId,
        'amount': amount,
        'phoneNumber': formattedPhone,
        'status': 'pending', // pending, completed, failed
        'method': 'MPESA',
        'checkoutRequestId': checkoutRequestId,
        'merchantRequestId': result['MerchantRequestID'],
        'initiatedAt': Timestamp.now(),
        'description': 'Rent payment for $propertyName',
        'responseCode': responseCode,
        'responseDescription': result['ResponseDescription'],
      });
      
    } catch (e) {
      print('Payment initiation failed: $e');
      rethrow;
    }
  }

  Future<String> checkPaymentStatus(String checkoutRequestId) async {
    try {
      final result = await _mpesaService.queryTransactionStatus(checkoutRequestId);
      final responseCode = result['ResponseCode'];
      // Note: Daraja Query result parsing is complex, usually check 'ResultCode' inside 'Result'
      // For simple polling, we might just look for success indication
      
      // Update local record if found?
      // In a real backend app, the callback updates the record. 
      // Here we might manually update if we confirm success.
      
      return responseCode == '0' ? 'completed' : 'pending';
    } catch (e) {
      print('Status check failed: $e');
      return 'unknown';
    }
  }
}

// Helper for min
class Math {
  static int min(int a, int b) => (a < b) ? a : b;
}
