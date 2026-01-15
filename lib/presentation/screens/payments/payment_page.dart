import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/repositories/payment_repository.dart';
import '../../../../providers/auth_provider.dart';

class PaymentPage extends StatefulWidget {
  final String applicationId;
  final double amount;

  const PaymentPage({
    super.key,
    required this.applicationId,
    required this.amount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _phoneController = TextEditingController();
  final _repository = PaymentRepository();
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill phone from auth if available
    final auth = context.read<AuthProvider>();
    if (auth.userProfile?.phone != null) {
      _phoneController.text = auth.userProfile!.phone!;
    }
  }

  Future<void> _initiatePayment() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Initiating payment...';
    });

    try {
      final auth = context.read<AuthProvider>();
      
      await _repository.initiatePayment(
        applicationId: widget.applicationId,
        tenantId: auth.firebaseUser!.uid,
        phoneNumber: _phoneController.text.trim(),
        amount: widget.amount, 
        propertyName: 'Property Lease', // Could fetch name if needed
      );

      setState(() {
        _statusMessage = 'Request sent to your phone. Please enter your PIN.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment request sent! Check your phone.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Here we could start polling for status or just wait for user to confirm
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Payment initiation failed: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.payment, size: 64, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              'Amount Due',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            Text(
              'KES ${widget.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Phone Number',
                hintText: 'e.g. 0712345678',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_android),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _initiatePayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Pay with M-Pesa'),
            ),
          ],
        ),
      ),
    );
  }
}
