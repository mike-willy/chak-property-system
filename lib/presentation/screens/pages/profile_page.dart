import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/application_provider.dart';
import '../../../../data/models/application_model.dart';
import '../properties/pages/application_status_page.dart';
import '../auth/widgets/auth_gate.dart';

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
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthGate()),
                  (route) => false,
                );
              }
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

            // Latest Application Status Section
            const Text(
              'Latest Application',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            
            // Application Section - Show only latest
            _buildLatestApplicationSection(context, user.id),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestApplicationSection(BuildContext context, String userId) {
    final applicationProvider = context.watch<ApplicationProvider>();
    final auth = context.watch<AuthProvider>();
    final userEmail = auth.userProfile?.email;
    
    return StreamBuilder<List<ApplicationModel>>(
      stream: applicationProvider.getTenantApplicationsStream(userId, email: userEmail),
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
                    'Error loading application',
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
              children: [
                Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade600),
                const SizedBox(height: 12),
                const Text(
                  'No applications yet',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit an application to track your status here',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Get only the most recent application
        final applications = List<ApplicationModel>.from(snapshot.data!);
        applications.sort((a, b) => b.appliedDate.compareTo(a.appliedDate));
        final latestApplication = applications.first;

        return _buildLatestApplicationCard(context, latestApplication, applications.length);
      },
    );
  }

  Widget _buildLatestApplicationCard(BuildContext context, ApplicationModel application, int totalApplications) {
    final status = application.status.value;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
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
                builder: (context) => ApplicationStatusPage(applicationId: application.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge - Large and centered
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: statusColor, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Property Info
                Center(
                  child: Column(
                    children: [
                      Text(
                        application.propertyName ?? 'Property Application',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4E95FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Unit ${application.unitNumber ?? application.unitName ?? application.unitId}',
                          style: const TextStyle(
                            color: Color(0xFF4E95FF),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Status Message
                if (status.toLowerCase() == 'rejected' && application.rejectionReason != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rejection Reason',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                application.rejectionReason!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (status.toLowerCase() == 'approved')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.celebration_outlined, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Congratulations! Your application has been approved',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (status.toLowerCase() == 'pending')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Your application is being reviewed',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Application Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text(
                            'Applied on:',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(application.appliedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (application.monthlyRent != null) ...[
                        const SizedBox(height: 12),
                        Divider(height: 1, color: Colors.grey.shade800),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.attach_money, size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text(
                              'Monthly Rent:',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                            const Spacer(),
                            Text(
                              'KES ${application.monthlyRent!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // View Details Button
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4E95FF), Color(0xFF3B7DD8)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4E95FF).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Full Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),

                // Show total applications count if more than 1
                if (totalApplications > 1) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'You have ${totalApplications - 1} other application${totalApplications > 2 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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