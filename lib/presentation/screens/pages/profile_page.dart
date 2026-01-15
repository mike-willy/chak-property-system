import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../properties/pages/application_status_page.dart';
import '../../../../data/models/user_model.dart';

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
                    backgroundImage: user.profileImage != null
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: user.profileImage == null
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
                    label: Text(user.role.value.toUpperCase()),
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
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.id)
                        .get(),
                    builder: (context, snapshot) {
                      String idNumber = 'Not set';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        if (data.containsKey('idNumber')) {
                          idNumber = data['idNumber'] ?? 'Not set';
                        }
                      }
                      return ListTile(
                        leading: const Icon(Icons.badge),
                        title: const Text('ID Number'),
                        subtitle: Text(idNumber),
                      );
                    },
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
            _buildApplicationsSection(user.id),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsSection(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tenantApplications')
          .where('tenantId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true) // Sort by latest first
          .snapshots(),
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

        final applications = snapshot.data!.docs;

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

  Widget _buildApplicationCard(BuildContext context, DocumentSnapshot appDoc) {
    final appData = appDoc.data() as Map<String, dynamic>;
    final status = appData['status'] ?? 'pending';
    final propertyName = appData['propertyName'] ?? 'Property';
    final unitName = appData['unitName'] ?? 'Unit';
    final submittedAt = (appData['submittedAt'] as Timestamp?)?.toDate();
    
    // Get status color and icon
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'withdrawn':
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApplicationStatusPage(
                applicationId: appDoc.id,
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
              Text(
                propertyName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                unitName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              if (submittedAt != null)
                Text(
                  'Submitted: ${_formatDate(submittedAt)}',
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

  void _showAllApplications(BuildContext context, List<DocumentSnapshot> applications) {
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
              final appDoc = applications[index];
              final appData = appDoc.data() as Map<String, dynamic>;
              final status = appData['status'] ?? 'pending';
              final propertyName = appData['propertyName'] ?? 'Property';
              final submittedAt = (appData['submittedAt'] as Timestamp?)?.toDate();
              
              return ListTile(
                title: Text(propertyName),
                subtitle: Text('Submitted: ${_formatDate(submittedAt ?? DateTime.now())}'),
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
                        applicationId: appDoc.id,
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
}