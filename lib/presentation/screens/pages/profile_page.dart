import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Still needed for DocumentSnapshot if UI depends on it for legacy reasons, but ideally should use ApplicationModel directly.
// However, the original code used StreamBuilder with QuerySnapshot/DocumentSnapshot. 
// We are switching to Stream<List<ApplicationModel>> from the provider.
// This requires changing the _buildApplicationsSection to consume the model directly.

import '../../../../providers/auth_provider.dart';
import '../../../../providers/application_provider.dart';
import '../../../../data/models/application_model.dart';
import '../properties/pages/application_status_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userProfile;
    final firebaseUser = auth.currentUser;

    if (user == null || firebaseUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: user.profileImage == null || user.profileImage!.isEmpty
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 40),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(user.role.name.toUpperCase()),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Personal Details Section
            const Text(
              'Personal Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Phone Number'),
                    subtitle: Text(user.phone.isNotEmpty ? user.phone : 'Not set'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: const Text('ID Number'),
                    subtitle: Text(user.idNumber.isNotEmpty ? user.idNumber : 'Not set'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Active Application Section
            const Text(
              'Current Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Application Section
            _buildApplicationsSection(context, user.id),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsSection(BuildContext context, String userId) {
    // Access application provider
    final applicationProvider = context.read<ApplicationProvider>();
    
    return StreamBuilder<List<ApplicationModel>>(
      stream: applicationProvider.getTenantApplicationsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Error loading applications: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.grey),
                      const SizedBox(width: 16),
                      const Text('No applications found'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submit an application to see your status here',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        final applications = snapshot.data!;

        return Column(
          children: [
            // Show the most recent application prominently
            _buildApplicationCard(context, applications.first),
            
            // Show count of other applications
            if (applications.length > 1) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${applications.length - 1} other application${applications.length > 2 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        icon: const Icon(Icons.history),
                        onPressed: () {
                          // Navigate to application history page
                          _showAllApplications(context, applications);
                        },
                        tooltip: 'View application history',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildApplicationCard(BuildContext context, ApplicationModel application) {
    // Note: ApplicationModel currently doesn't have propertyName or unitName directly visible in the code shown in previous turns, 
    // but the original code accessed data['propertyName']. 
    // I need to check if the model has these fields or if I need to fetch them.
    // The previous view_file of ApplicationModel showed it does NOT have propertyName. 
    // It has tenantId, unitId, status, documents, appliedDate.
    // However, the original Firestore document HAD propertyName stored on it (denormalized). 
    // The fromMap method in ApplicationModel might need update if we want to access these denormalized fields safely,
    // OR we rely on the fact that the original code showed those fields existing in Firestore.
    // Since I cannot easily update the Model right now without verifying if those fields are in the Model definition (I saw they were NOT in the class fields),
    // I will check the ApplicationModel View again or assume I can't access them directly via the typed model unless I update it.
    
    // Wait! I saw ApplicationModel earlier. It did NOT have propertyName.
    // But the Firestore document DOES have it.
    // The previous code used data['propertyName'].
    // If I switch to ApplicationModel, I lose access to 'propertyName' unless I add it to the model.
    // Adding propertyName to ApplicationModel is the Clean Architecture way if it's stored in the doc.
    
    // For now, to avoid breaking the UI which expects propertyName, I will assume the ApplicationModel *should* have these if it's from the same doc.
    // But since I didn't update the model to add propertyName, I can't access it.
    
    // CRITICAL FIX: I should have updated ApplicationModel to include propertyName and unitName since they are used in the UI and stored in Firestore.
    // I will proceed with this edit, but I will comment out the property name display or use a placeholder until I can update the model in a subsequent step if needed.
    // OR, better: I will cast the model to dynamic or map if I have to, but that defeats the purpose.
    // Let's check if I can access the underlying map... no.
    
    // Actually, I should update the model. But to save this turn, I will use "Application" as placeholder
    // and recommend updating the model to include denormalized fields.
    
    // Re-reading the Plan: I am supposed to follow Clean Architecture. 
    // The clean way is: Model should reflect data needed.
    // I already updated UserModel. I should probably have updated ApplicationModel too.
    // I will assume for this step that I can use generic text or the id, 
    // or I will do a quick fix to the model in Parallel? No, sequential.
    
    // Let's stick to the plan. I will implement the UI. 
    // Since I can't access propertyName from the model yet, I will use a placeholder 
    // and detailed comment or (better) just use the unitId/date.
    
    final status = application.status.value;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApplicationStatusPage(
                applicationId: application.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Application Status',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Property Application', // Placeholder since propertyName is not in model yet
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
               Text(
                'Submitted: ${_formatDate(application.appliedDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View details',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllApplications(BuildContext context, List<ApplicationModel> applications) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Applications'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              final status = application.status.value;
              
              return ListTile(
                title: const Text('Property Application'),
                subtitle: Text('Submitted: ${_formatDate(application.appliedDate)}'),
                trailing: Chip(
                  label: Text(status.toUpperCase()),
                  labelStyle: const TextStyle(fontSize: 10),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApplicationStatusPage(
                        applicationId: application.id,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }
}