import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/widgets/auth_gate.dart';
import '../../../../data/models/application_model.dart';
import '../../../../data/models/payment_model.dart';
import '../../../../data/repositories/payment_repository.dart';
import 'initial_payment_page.dart';

class ApplicationStatusPage extends StatelessWidget {
  final String applicationId;

  const ApplicationStatusPage({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Status'),
        automaticallyImplyLeading: false, // Don't allow going back easily to duplicate
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tenantApplications')
            .doc(applicationId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Application not found'));
          }

          // Convert data using ApplicationModel safe factory? Or just map manually like before but safer
          // Let's use map manually to keep it simple but we need ApplicationModel for Next Page
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final appModel = ApplicationModel.fromMap(snapshot.data!.id, data);
          final status = appModel.status.value;
          
          
          return StreamBuilder<List<PaymentModel>>(
            // Only check payments if approved
            stream: status == 'approved' 
                ? context.read<PaymentRepository>().getCompletedPaymentsStreamByApplicationId(applicationId) 
                : Stream.value([]),
            builder: (context, paymentSnapshot) {
              final isPaid = paymentSnapshot.hasData && paymentSnapshot.data!.isNotEmpty;
              final isLoadingPayment = paymentSnapshot.connectionState == ConnectionState.waiting && paymentSnapshot.data == null;

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusIcon(status),
                    const SizedBox(height: 24),
                    Text(
                      'Application for ${appModel.propertyName ?? 'Property'}',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getStatusTitle(status),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getStatusMessage(status, isPaid),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (status == 'rejected' && appModel.rejectionReason != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reason: ${appModel.rejectionReason}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 48),
                    
                    if (status == 'approved') ...[
                      if (isLoadingPayment)
                        const Center(child: CircularProgressIndicator())
                      else if (isPaid)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => const AuthGate()),
                                (route) => false);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Continue to Dashboard'),
                        )
                      else
                         ElevatedButton(
                          onPressed: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(builder: (_) => InitialPaymentPage(application: appModel)),
                             );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Make Payment'),
                        ),
                    ],

                    if (status == 'pending') ...[
                       OutlinedButton(
                        onPressed: () {
                             // Optional: Add refresh or check status logic if not streaming
                        },
                        child: const Text('Checking Status...'),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Cancel Application', style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                           // ... (same delete logic)
                           final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Cancel Application?'),
                                content: const Text('Are you sure you want to cancel this application? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('No, Keep It'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Yes, Cancel'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await FirebaseFirestore.instance
                                  .collection('tenantApplications')
                                  .doc(applicationId)
                                  .delete();
                              
                              if (context.mounted) {
                                Navigator.pop(context); // Go back to property
                              }
                            }
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status.toLowerCase()) {
      case 'approved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.hourglass_top;
        color = Colors.orange;
    }

    return CircleAvatar(
      radius: 48,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, size: 48, color: color),
    );
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Application Approved!';
      case 'rejected':
        return 'Application Declined';
      default:
        return 'Under Review';
    }
  }

  String _getStatusMessage(String status, [bool isPaid = false]) {
    switch (status.toLowerCase()) {
      case 'approved':
        if (isPaid) {
           return 'Congratulations! Your application is approved and initial fees are paid. You can now access your dashboard.';
        }
        return 'Congratulations! Your application has been approved. Please pay the initial rent and deposit to finalize your lease.';
      case 'rejected':
        return 'We are sorry, but your application has been declined at this time. Please contact the property manager for more information.';
      default:
        return 'Your application is currently pending review by the property manager. We will notify you once a decision has been made.';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
