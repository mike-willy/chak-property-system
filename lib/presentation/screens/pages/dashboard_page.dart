import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Providers
import '../../../providers/auth_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../providers/tenant_provider.dart';
import '../../../providers/maintenance_provider.dart';
import '../../../providers/notification_provider.dart';

// Models
import '../../../data/models/tenant_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/address_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/maintenance_model.dart';
import '../../../data/models/notification_model.dart';

// Pages
import '../properties/pages/property_list_page.dart';
import 'messages_page.dart';
import 'maintenance_page.dart';
import 'profile_page.dart';

// Widgets
import '../widgets/dashboard_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardHome(onNavigate: _onNavigate),
      const PropertyListPage(),
      const MessagesPage(),
      const MaintenancePage(),
      const ProfilePage(),
    ];
  }

  void _onNavigate(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141725), 
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2235), // Dark Bar Background
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF4E95FF), // Bright Blue
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
          onTap: _onNavigate,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Rentals'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
            BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined), activeIcon: Icon(Icons.build_circle), label: 'Maint.'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  final Function(int) onNavigate;

  const DashboardHome({
    super.key,
    required this.onNavigate,
  });

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final tenantProvider = context.read<TenantProvider>();
    final maintenanceProvider = context.read<MaintenanceProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    if (authProvider.isTenant && authProvider.firebaseUser != null) {
      await tenantProvider.loadTenantData();
      if (tenantProvider.tenant != null) {
        await Future.wait([
          maintenanceProvider.loadRequests(),
          notificationProvider.loadNotifications(authProvider.firebaseUser!.uid),
        ]);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<AuthProvider, TenantProvider, MaintenanceProvider, NotificationProvider>(
      builder: (context, authProvider, tenantProvider, maintenanceProvider, notificationProvider, _) {
        final user = authProvider.userProfile;
        
        // Derive data
        final userName = user?.name.split(' ')[0] ?? 'User';
        final propertyAddress = tenantProvider.unit != null 
            ? 'Unit ${tenantProvider.unit!.unitNumber}'
            : '123 Maple Street, Apt 4B';
        
        // Payment Data
        final nextPayment = tenantProvider.payments.firstWhere(
          (p) => p.status == PaymentStatus.pending,
          orElse: () => PaymentModel(
            id: 'dummy', leaseId: '', tenantId: '', 
            amount: 0.00, method: PaymentMethod.card, status: PaymentStatus.completed, 
            dueDate: DateTime.now()
          ),
        );
        
        final hasPendingHeader = nextPayment.status == PaymentStatus.pending;
        final paymentAmount = hasPendingHeader ? nextPayment.amount : 0.00;
        final paymentDate = hasPendingHeader ? nextPayment.dueDate : DateTime.now();

        // Combine Activities
        final allActivities = <Map<String, dynamic>>[];
        
        for (var req in maintenanceProvider.requests) {
           allActivities.add({
             'type': 'maintenance',
             'date': req.createdAt,
             'data': req,
           });
        }
        for (var pay in tenantProvider.payments) {
           allActivities.add({
             'type': 'payment',
             'date': pay.dueDate,
             'data': pay,
           });
        }
        for (var notif in notificationProvider.notifications) {
           allActivities.add({
             'type': 'notification',
             'date': notif.createdAt,
             'data': notif,
           });
        }

        // Robust sort
        allActivities.sort((a, b) {
            final dateA = a['date'] as DateTime?;
            final dateB = b['date'] as DateTime?;
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1; // Nulls last
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
        });
        final recentActivities = allActivities.take(5).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header
                    DashboardHeader(
                      userName: userName,
                      address: propertyAddress,
                      profileImage: user?.profileImage,
                      onNotificationTap: () {},
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 2. Payment Card
                    PaymentCard(
                      amount: paymentAmount,
                      dueDate: paymentDate,
                      onPayTap: () {
                          // Navigate to payments
                      },
                      isLoading: tenantProvider.isLoading,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 3. Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ActionButton(
                            icon: Icons.build,
                            label: 'Request Repair',
                            iconColor: Colors.blue,
                            iconBgColor: Colors.blue.shade50,
                            onTap: () => widget.onNavigate(3), // Maintenance Tab
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ActionButton(
                            icon: Icons.description,
                            label: 'View Lease',
                            iconColor: Colors.blue,
                            iconBgColor: Colors.blue.shade50,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Lease Document'),
                                  content: const Text('Lease viewing functionality is coming soon.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Message Landlord
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                           BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.chat_bubble, color: Colors.blue),
                        ),
                        title: const Text(
                          'Message Landlord',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () => widget.onNavigate(2), // Messages Tab
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 4. Recent Activity
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (recentActivities.isEmpty)
                       const Padding(
                         padding: EdgeInsets.all(16.0),
                         child: Center(
                           child: Text("No recent activity.", style: TextStyle(color: Colors.grey))
                         ),
                       )
                    else
                       ...recentActivities.map((activity) {
                          final type = activity['type'] as String;
                          final date = activity['date'] as DateTime;
                          
                          if (type == 'maintenance') {
                             final req = activity['data'] as MaintenanceModel;
                             return RecentActivityItem(
                               icon: Icons.build_circle,
                               iconColor: Colors.green,
                               iconBgColor: Colors.green.shade50,
                               title: req.title,
                               subtitle: 'Maintenance • ${req.status.value}',
                               date: _formatDate(date),
                             );
                          } else if (type == 'payment') {
                             final pay = activity['data'] as PaymentModel;
                             return RecentActivityItem(
                               icon: Icons.payment,
                               iconColor: Colors.blue,
                               iconBgColor: Colors.blue.shade50,
                               title: 'Payment Confirmed',
                               subtitle: '\$${pay.amount}',
                               date: _formatDate(date),
                             );
                          } else {
                             final notif = activity['data'] as NotificationModel;
                             return RecentActivityItem(
                               icon: Icons.notifications_active,
                               iconColor: Colors.orange,
                               iconBgColor: Colors.orange.shade50,
                               title: notif.title, 
                               subtitle: 'Notice',
                               date: _formatDate(date),
                             );
                          }
                       }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }
}