import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/mpesa_service.dart';
import '../models/payment_model.dart';

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
      return responseCode == '0' ? 'completed' : 'pending';
    } catch (e) {
      print('Status check failed: $e');
      return 'unknown';
    }
  }

  // Get payments for a specific tenant
  Future<List<PaymentModel>> getPaymentsByTenantId(String tenantId) async {
    try {
      final querySnapshot = await _paymentsRef
          .where('tenantId', isEqualTo: tenantId)
          .orderBy('initiatedAt', descending: true) // Assuming 'initiatedAt' is the timestamp
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) {
        // Map Firestore doc to PaymentModel
        final data = doc.data() as Map<String, dynamic>;
        
        return PaymentModel(
          id: doc.id,
          leaseId: data['applicationId'] ?? '', 
          tenantId: data['tenantId'] ?? '',
          amount: (data['amount'] as num).toDouble(),
          method: PaymentMethodExtension.fromString(data['method'] ?? 'mobile'),
          status: PaymentStatusExtension.fromString(data['status'] ?? 'pending'),
          transactionId: data['checkoutRequestId'],
          dueDate: (data['initiatedAt'] as Timestamp).toDate(), 
          paidDate: data['status'] == 'completed' ? (data['updatedAt'] as Timestamp?)?.toDate() : null,
        );
      }).toList();
    } catch (e) {
      print('Error fetching payments: $e');
      return [];
    }
  }
}

// Helper for min
class Math {
  static int min(int a, int b) => (a < b) ? a : b;
}
