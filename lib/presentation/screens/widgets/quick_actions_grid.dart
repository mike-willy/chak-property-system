import 'package:flutter/material.dart';

class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onPayRent;
  final VoidCallback onRequestMaintenance;
  final VoidCallback onViewMessages; // Keep for fallback or other actions
  final VoidCallback onViewLease; // Renamed to Lease

  const QuickActionsGrid({
    super.key,
    required this.onPayRent,
    required this.onRequestMaintenance,
    required this.onViewMessages,
    required this.onViewLease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            label: 'Report Issue',
            icon: Icons.build,
            color: const Color(0xFF2C2F42), // Darker card bg
            iconColor: Colors.purple.shade300,
            iconBgColor: Colors.purple.withOpacity(0.2),
            onTap: onRequestMaintenance,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            label: 'Lease Rules',
            icon: Icons.description, 
            color: const Color(0xFF2C2F42),
            iconColor: Colors.orange.shade300,
            iconBgColor: Colors.orange.withOpacity(0.2),
            onTap: onViewLease, 
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String label,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
