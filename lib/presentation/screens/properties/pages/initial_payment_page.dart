
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../data/models/application_model.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/models/tenant_model.dart';
import '../../../../data/repositories/payment_repository.dart';
import '../../../../data/repositories/property_repository.dart';
import '../../../../data/repositories/tenant_repository.dart';
import '../../../../providers/auth_provider.dart';
import '../../auth/widgets/auth_gate.dart';

class InitialPaymentPage extends StatefulWidget {
  final ApplicationModel application;

  const InitialPaymentPage({super.key, required this.application});

  @override
  State<InitialPaymentPage> createState() => _InitialPaymentPageState();
}

class _InitialPaymentPageState extends State<InitialPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  String? _error;
  PropertyModel? _property;
  
  // Payment tracking
  String? _paymentId;
  String? _checkoutRequestId;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }



  Future<void> _loadData() async {
    try {
      if (widget.application.propertyId == null) {
        throw Exception('Property ID missing from application');
      }

      final repo = context.read<PropertyRepository>();
      final result = await repo.getPropertyById(widget.application.propertyId!);
      
      result.fold(
        (failure) => setState(() => _error = failure.message),
        (property) {
          setState(() {
            _property = property;
            _isLoading = false;
          });
          _prefillPhone();
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load details: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _prefillPhone() {
    final auth = context.read<AuthProvider>();
    if (widget.application.phone != null && widget.application.phone!.isNotEmpty) {
      _phoneController.text = widget.application.phone!;
    } else if (auth.userProfile?.phone != null) {
      _phoneController.text = auth.userProfile!.phone;
    }
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_property == null) return;

    setState(() {
      _isProcessingPayment = true;
      _error = null;
    });

    final totalAmount = (widget.application.monthlyRent ?? 0.0) + _property!.deposit;

    try {
      final repo = context.read<PaymentRepository>();
      final paymentId = await repo.initiatePayment(
        applicationId: widget.application.id,
        tenantId: widget.application.tenantId,
        phoneNumber: _phoneController.text.trim(),
        amount: totalAmount,
        propertyName: _property!.title,
      );

      setState(() {
        _paymentId = paymentId;
      });

      // Fetch the payment to get checkoutRequestId for polling
      final payment = await repo.getPaymentById(paymentId);
      if (payment != null && payment.transactionId != null) {
         _startStatusPolling(paymentId, payment.transactionId!);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment request sent. Please check your phone.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Payment initiation failed: $e';
          _isProcessingPayment = false;
        });
      }
    }
  }

  StreamSubscription<DocumentSnapshot>? _paymentSubscription;

  void _startStatusPolling(String paymentId, String checkoutRequestId) {
    // 1. Listen to Firestore changes (Primary Source of Truth)
    _paymentSubscription?.cancel();
    _paymentSubscription = FirebaseFirestore.instance
        .collection('payments')
        .doc(paymentId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        
        if (status == 'completed') {
           _stopPolling();
           _handlePaymentSuccess();
        } else if (status == 'failed') {
           _stopPolling();
           setState(() {
             _error = 'Payment failed: ${data['statusDescription'] ?? 'Unknown error'}';
             _isProcessingPayment = false;
           });
        }
      }
    });

    // 2. Background Polling (Active Check)
    _statusCheckTimer?.cancel();
    int checkCount = 0;
    const maxChecks = 20; // 2 minutes

    _statusCheckTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
      checkCount++;
      if (checkCount > maxChecks) {
         // Don't fail UI, just stop polling. Firestore stream might still update late.
         timer.cancel();
         return;
      }

      try {
        final repo = context.read<PaymentRepository>();
        final status = await repo.checkPaymentStatus(checkoutRequestId);
        
        if (status != 'pending' && status != 'unknown') {
           // Update Firestore. The Stream listener above will handle the UI update.
           await repo.updatePaymentStatus(
             paymentId: paymentId, 
             status: status
           );
           
           if (status == 'completed' || status == 'failed') {
             timer.cancel();
           }
        }
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }

  void _stopPolling() {
    _statusCheckTimer?.cancel();
    _paymentSubscription?.cancel();
  }

  @override
  void dispose() {
    _stopPolling();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _finalizeLease() async {
    try {
       final tenantRepo = context.read<TenantRepository>();
       
       // 1. Check if tenant record exists
       final existingTenant = await tenantRepo.getTenantByUserId(widget.application.tenantId);
       
       final tenantData = TenantModel(
         id: existingTenant?.id ?? '', // ID ignored on create, used on update
         userId: widget.application.tenantId, 
         unitId: widget.application.unitId,
         fullName: widget.application.fullName ?? 'Unknown',
         email: widget.application.email ?? '',
         phone: widget.application.phone ?? '',
         propertyId: widget.application.propertyId ?? '',
         propertyName: _property?.title ?? '',
         unitNumber: widget.application.unitNumber ?? '',
         rentAmount: widget.application.monthlyRent ?? 0.0,
         leaseStartDate: widget.application.leaseStart ?? DateTime.now(),
         leaseEndDate: widget.application.leaseEnd,
         status: TenantStatus.active,
         createdAt: existingTenant?.createdAt ?? DateTime.now(),
         updatedAt: DateTime.now(),
       ).toMap(); // We need to pass Map to createTenant/updateTenant? Repo expects Map for create, but object for update?
       // Repo: createTenant(Map), updateTenant(String, Map)
       
       if (existingTenant != null) {
          await tenantRepo.updateTenant(existingTenant.id, tenantData);
       } else {
          await tenantRepo.createTenant(tenantData);
       }

       // 2. Mark unit as occupied
       await tenantRepo.occupyUnit(
         unitId: widget.application.unitId,
         tenantId: widget.application.tenantId, // Store userId as tenantId in unit? Or the docId? 
         // Repo occupyUnit expects "tenantId" and "tenantName". 
         // Usually unit.tenantId links to the User ID or Tenant Document ID. 
         // Let's use User ID (application.tenantId) for consistency with getTenantByUserId
         tenantName: widget.application.fullName ?? 'Unknown', 
       );
       
       // 3. Mark application as completed/leased? 
       // Currently we keep it as 'approved'. Maybe add a field 'isLeaseFinalized' to application? 
       // For now, allow multiple entries.
       
    } catch (e) {
      print('Error finalizing lease: $e');
      // Non-blocking error, user has paid so let them in. 
      // Admin can manually fix if needed, or retry on dashboard load.
    }
  }

  void _handlePaymentSuccess() async {
    if (!mounted) return;
    
    // Create Tenant Record & Occupy Unit
    await _finalizeLease();
    
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
             Icon(Icons.check_circle, color: Colors.green),
             SizedBox(width: 8),
             Text('Payment Successful'),
          ],
        ),
        content: const Text('Your initial rent and deposit have been paid. Your lease is now active and you can access your dashboard!'),
        actions: [
          TextButton(
            onPressed: () {
               // Reload AuthProvider/TenantProvider? 
               // AuthGate/Dashboard should auto-refresh if they listen to streams.
               Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthGate()),
                  (route) => false,
               );
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_property == null) {
       return Scaffold(
         appBar: AppBar(title: const Text('Payment Error')),
         body: Center(child: Text(_error ?? 'Property details not found')),
       );
    }

    final rent = widget.application.monthlyRent ?? 0.0;
    final deposit = _property!.deposit;
    final total = rent + deposit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Almost There!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please pay the initial rent and security deposit to finalize your lease.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Breakdown Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                       _buildLineItem('First Month Rent', rent),
                       const Divider(),
                       _buildLineItem('Security Deposit', deposit),
                       const Divider(thickness: 2),
                       _buildLineItem('Total Due', total, isTotal: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              
              // M-Pesa Input
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'M-Pesa Phone Number',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: 'Format: 07XXXXXXXX or 2547XXXXXXXX'
                ),
                keyboardType: TextInputType.phone,
                enabled: !_isProcessingPayment,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  // Basic regex for Kenya numbers (loose)
                  if (!RegExp(r'^(?:254|\+254|0)?(7(?:(?:[0-9][0-9])|(?:[0-9][0-9]))[0-9]{6})$').hasMatch(value.replaceAll(' ', ''))) {
                      return 'Enter a valid valid M-Pesa number';
                  }
                  return null;
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                 Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],

              const SizedBox(height: 24),
              
              if (_isProcessingPayment)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Waiting for payment confirmation...')
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Pay KES ${total.toStringAsFixed(0)} with M-Pesa'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineItem(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            'KES ${amount.toStringAsFixed(2)}',
             style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.bold,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
