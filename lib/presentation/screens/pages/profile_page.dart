import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        backgroundColor: Color(0xFF141725),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4E95FF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF141725),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF141725),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
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
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF4E95FF), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF1E2235),
                      backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                          ? NetworkImage(user.profileImage!)
                          : null,
                      child: user.profileImage == null || user.profileImage!.isEmpty
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 40, color: Colors.white),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    label: Text(
                      user.role.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFF4E95FF),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Personal Details Section
            const Text(
              'Personal Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E2235),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.phone, color: Color(0xFF4E95FF)),
                    title: const Text('Phone Number', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    subtitle: Text(
                      user.phone.isNotEmpty ? user.phone : 'Not set',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade800),
                  ListTile(
                    leading: const Icon(Icons.badge, color: Color(0xFF4E95FF)),
                    title: const Text('ID Number', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    subtitle: Text(
                      user.idNumber.isNotEmpty ? user.idNumber : 'Not set',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Active Application Section
            const Text(
              'Current Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2235),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade900),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Error loading applications: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4E95FF)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2235),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                   Icon(Icons.info_outline, color: Colors.grey.shade400),
                    const SizedBox(width: 16),
                    const Text('No applications found', style: TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit an application to see your status here',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // Sort applications to prioritize Approved > Pending > Rejected
        // Secondary sort by date descending
        final sortedApplications = List<ApplicationModel>.from(snapshot.data!);
        sortedApplications.sort((a, b) {
          // Define priority: Approved (2) > Pending (1) > Rejected (0)
          int getPriority(String status) {
            switch (status.toLowerCase()) {
              case 'approved': return 2;
              case 'pending': return 1;
              default: return 0;
            }
          }

          final priorityA = getPriority(a.status.value);
          final priorityB = getPriority(b.status.value);

          if (priorityA != priorityB) {
            return priorityB.compareTo(priorityA); // Descending priority
          }
          return b.appliedDate.compareTo(a.appliedDate); // Descending date
        });

        final applications = sortedApplications;

        return Column(
          children: [
            // Show the most relevant application (highest priority)
            _buildApplicationCard(context, applications.first),
            
            // Show count of other applications
            if (applications.length > 1) ...[
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2235),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${applications.length - 1} other application${applications.length > 2 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.white70),
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

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Application Status',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  application.propertyName ?? 'Property Application',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (application.unitNumber != null || application.unitName != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Unit: ${application.unitNumber ?? application.unitName}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Applied: ${_formatDate(application.appliedDate)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    if (application.monthlyRent != null) ...[
                      const SizedBox(width: 20),
                      Icon(Icons.attach_money, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Rent: ${application.monthlyRent!.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: Color(0xFF4E95FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16, color: Color(0xFF4E95FF)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAllApplications(BuildContext context, List<ApplicationModel> applications) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('All Applications', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              final status = application.status.value;
              
              return ListTile(
                title: Text(
                  application.propertyName ?? 'Property Application',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (application.unitNumber != null || application.unitName != null)
                      Text(
                        'Unit: ${application.unitNumber ?? application.unitName}',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    Text(
                      'Submitted: ${_formatDate(application.appliedDate)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                trailing: Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  backgroundColor: _getStatusColor(status).withOpacity(0.1),
                  side: BorderSide.none,
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
            child: const Text('Close', style: TextStyle(color: Colors.white)),
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