import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../payments/payment_page.dart';
import '../../auth/widgets/auth_gate.dart';

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

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';
          final propertyName = data['propertyName'] ?? 'Property';

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusIcon(status),
                const SizedBox(height: 24),
                Text(
                  'Application for $propertyName',
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
                  _getStatusMessage(status),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (status == 'approved')
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
                  ),
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Property Details'),
                ),
              ],
            ),
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

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Congratulations! Your application has been approved. The unit has been assigned to you.';
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
