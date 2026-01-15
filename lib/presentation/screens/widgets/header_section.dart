import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? tenantId; // Add tenant ID
  final VoidCallback? onNotificationTap;

  const HeaderSection({
    super.key,
    required this.userName,
    required this.userRole,
    this.tenantId,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.2), // Background color
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $userName', // First name only ideally
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Dark theme text
                    ),
                  ),
                  if (tenantId != null)
                    Text(
                      'Tenant ID: #$tenantId',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Notification Bell
          IconButton(
            onPressed: onNotificationTap ?? () {},
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade800, // Dark background for button
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}
