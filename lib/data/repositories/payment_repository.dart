import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/mpesa_service.dart';
import '../models/payment_model.dart';
import 'dart:math' as math;

class PaymentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MpesaService _mpesaService = MpesaService();

  CollectionReference get _paymentsRef => _db.collection('payments');

  Future<String> initiatePayment({
    required String applicationId,
    required String tenantId,
    required String phoneNumber,
    required double amount,
    required String propertyName,
  }) async {
    try {
      // 1. Format phone number (remove leading 0 or +, ensure 254)
      String formattedPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '254${formattedPhone.substring(1)}';
      } else if (!formattedPhone.startsWith('254')) {
        formattedPhone = '254$formattedPhone';
      }

      print('Initiating payment for $phoneNumber ($formattedPhone) amount $amount');

      // 2. Initiate STK Push
      final result = await _mpesaService.initiateStkPush(
        phoneNumber: formattedPhone,
        amount: amount,
        accountReference: applicationId.substring(0, math.min(12, applicationId.length)),
        transactionDesc: 'Rent Payment',
      );

      // Check if STK push was successful
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to initiate payment');
      }

      final checkoutRequestId = result['checkoutRequestId'];
      final merchantRequestId = result['merchantRequestId'];

      // 3. Create Payment Record (Pending)
      final paymentDoc = await _paymentsRef.add({
        'applicationId': applicationId,
        'tenantId': tenantId,
        'amount': amount,
        'phoneNumber': formattedPhone,
        'status': 'pending', // pending, completed, failed, cancelled, timeout
        'method': 'mobile',
        'checkoutRequestId': checkoutRequestId,
        'merchantRequestId': merchantRequestId,
        'initiatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(), // Match PaymentInitiation
        'reference': applicationId.substring(0, math.min(12, applicationId.length)), // Match PaymentInitiation
        'description': 'Rent payment for $propertyName',
        'responseCode': result['responseCode'],
        'responseDescription': result['responseDescription'],
        'customerMessage': result['customerMessage'],
      });

      print('Payment record created: ${paymentDoc.id}');
      
      // Return the payment ID and checkoutRequestId
      return paymentDoc.id;
    } catch (e) {
      print('Payment initiation failed: $e');
      rethrow;
    }
  }

  // Check payment status by querying M-Pesa
  Future<String> checkPaymentStatus(String checkoutRequestId) async {
    try {
      // FIX: Add the named parameter
      final result = await _mpesaService.queryTransactionStatus(
        checkoutRequestId: checkoutRequestId,
      );
      
      final resultCode = result['ResultCode']?.toString() ?? '';
      
      // Map M-Pesa result codes to our status
      if (resultCode == '0') {
        return 'completed';
      } else if (resultCode == '1032') {
        return 'cancelled'; // User cancelled
      } else if (resultCode == '1037') {
        return 'timeout'; // Timeout
      } else if (resultCode.isNotEmpty) {
        return 'failed';
      }
      
      return 'pending';
    } catch (e) {
      print('Status check failed: $e');
      return 'unknown';
    }
  }

  // Update payment status in Firestore
  Future<void> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? mpesaReceiptNumber,
    String? resultDescription,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (mpesaReceiptNumber != null) {
        updateData['mpesaReceiptNumber'] = mpesaReceiptNumber;
      }

      if (resultDescription != null) {
        updateData['resultDescription'] = resultDescription;
      }

      if (status == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _paymentsRef.doc(paymentId).update(updateData);
      print('Payment $paymentId status updated to $status');
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow;
    }
  }

  // Get payment by checkout request ID
  Future<PaymentModel?> getPaymentByCheckoutRequestId(String checkoutRequestId) async {
    try {
      final querySnapshot = await _paymentsRef
          .where('checkoutRequestId', isEqualTo: checkoutRequestId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;

      return PaymentModel(
        id: doc.id,
        leaseId: data['applicationId'] ?? '',
        tenantId: data['tenantId'] ?? '',
        amount: (data['amount'] as num).toDouble(),
        method: PaymentMethodExtension.fromString(data['method'] ?? 'mobile'),
        status: PaymentStatusExtension.fromString(data['status'] ?? 'pending'),
        transactionId: data['checkoutRequestId'],
        dueDate: (data['initiatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        paidDate: data['completedAt'] != null
            ? (data['completedAt'] as Timestamp).toDate()
            : null,
      );
    } catch (e) {
      print('Error fetching payment: $e');
      return null;
    }
  }

  // Get payments for a specific tenant
  Future<List<PaymentModel>> getPaymentsByTenantId(String tenantId) async {
    try {
      final querySnapshot = await _paymentsRef
          .where('tenantId', isEqualTo: tenantId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return PaymentModel(
          id: doc.id,
          leaseId: data['applicationId'] ?? '',
          tenantId: data['tenantId'] ?? '',
          amount: (data['amount'] as num).toDouble(),
          method: PaymentMethodExtension.fromString(data['method'] ?? 'mobile'),
          status: PaymentStatusExtension.fromString(data['status'] ?? 'pending'),
          transactionId: data['checkoutRequestId'],
          dueDate: (data['initiatedAt'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          paidDate: data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error fetching payments: $e');
      return [];
    }
  }

  // Stream payments for a tenant
  Stream<List<PaymentModel>> getPaymentsStream(String tenantId) {
    return _paymentsRef
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return PaymentModel(
          id: doc.id,
          leaseId: data['applicationId'] ?? '',
          tenantId: data['tenantId'] ?? '',
          amount: (data['amount'] as num).toDouble(),
          method: PaymentMethodExtension.fromString(data['method'] ?? 'mobile'),
          status: PaymentStatusExtension.fromString(data['status'] ?? 'pending'),
          transactionId: data['checkoutRequestId'],
          dueDate: (data['initiatedAt'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          paidDate: data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    });
  }

  // Stream payments for a list of IDs (User ID + All Tenant IDs)
  Stream<List<PaymentModel>> getPaymentsStreamForList(List<String> ids) {
    // Remove duplicates and empty strings
    final distinctIds = ids.where((id) => id.isNotEmpty).toSet().toList();

    if (distinctIds.isEmpty) {
      return Stream.value([]);
    }
    
    // Firestore 'whereIn' supports up to 10 values
    final queryIds = distinctIds.take(10).toList();

    return _paymentsRef
        .where('tenantId', whereIn: queryIds)
        .orderBy('createdAt', descending: true)
        .limit(50) // Increased limit to seeing more history
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return PaymentModel(
          id: doc.id,
          leaseId: data['applicationId'] ?? '',
          tenantId: data['tenantId'] ?? '',
          amount: (data['amount'] as num).toDouble(),
          method: PaymentMethodExtension.fromString(data['method'] ?? 'mobile'),
          status: PaymentStatusExtension.fromString(data['status'] ?? 'pending'),
          transactionId: data['checkoutRequestId'],
          dueDate: (data['initiatedAt'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          paidDate: data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    });
  }

  // Get single payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final doc = await _paymentsRef.doc(paymentId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;

      return PaymentModel(
        id: doc.id,
        leaseId: data['applicationId'] ?? '',
        tenantId: data['tenantId'] ?? '',
        amount: (data['amount'] as num).toDouble(),
        method: PaymentMethodExtension.fromString(data['method'] ?? 'mobile'),
        status: PaymentStatusExtension.fromString(data['status'] ?? 'pending'),
        transactionId: data['checkoutRequestId'],
        dueDate: (data['initiatedAt'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        paidDate: data['completedAt'] != null
            ? (data['completedAt'] as Timestamp).toDate()
            : null,
      );
    } catch (e) {
      print('Error fetching payment: $e');
      return null;
    }
  }

  // Get completed payments for an application
  Future<List<PaymentModel>> getCompletedPaymentsByApplicationId(String applicationId) async {
    try {
      final querySnapshot = await _paymentsRef
          .where('applicationId', isEqualTo: applicationId)
          .where('status', isEqualTo: 'completed')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Handle optional fields safely
        return PaymentModel(
          id: doc.id,
          leaseId: data['applicationId'] ?? '',
          tenantId: data['tenantId'] ?? '',
          amount: (data['amount'] as num).toDouble(),
          method: PaymentMethodExtension.fromString(data['method'] ?? 'mobile'),
          status: PaymentStatusExtension.fromString(data['status'] ?? 'pending'),
          transactionId: data['checkoutRequestId'],
          dueDate: (data['initiatedAt'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          paidDate: data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error fetching payments for application: $e');
      return [];
    }
  }

  // Stream completed payments for an application
  Stream<List<PaymentModel>> getCompletedPaymentsStreamByApplicationId(String applicationId) {
    return _paymentsRef
        .where('applicationId', isEqualTo: applicationId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        return PaymentModel(
          id: doc.id,
          leaseId: data['applicationId'] ?? '',
          tenantId: data['tenantId'] ?? '',
          amount: (data['amount'] as num).toDouble(),
          method: PaymentMethodExtension.fromString(data['method'] ?? 'mobile'),
          status: PaymentStatusExtension.fromString(data['status'] ?? 'pending'),
          transactionId: data['checkoutRequestId'],
          dueDate: (data['initiatedAt'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          paidDate: data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    });
  }

  // Stream all payments (for Landlord History)
  Stream<List<PaymentModel>> getAllPaymentsStream() {
    return _paymentsRef
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return PaymentModel(
          id: doc.id,
          leaseId: data['applicationId'] ?? '',
          tenantId: data['tenantId'] ?? '',
          amount: (data['amount'] as num).toDouble(),
          method: PaymentMethodExtension.fromString(data['method'] ?? 'mobile'),
          status: PaymentStatusExtension.fromString(data['status'] ?? 'pending'),
          transactionId: data['checkoutRequestId'],
          dueDate: (data['initiatedAt'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          paidDate: data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    });
  }
}