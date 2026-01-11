import 'package:flutter/material.dart';
import '../../../core/widgets/common_widgets.dart';

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('See All', style: TextStyle(color: Colors.blue)),
          ],
        ),
        const SizedBox(height: 16),
        const _ActivityItem(
          icon: Icons.receipt_long,
          title: 'Rent Payment Confirmed',
          subtitle: 'Transaction ID: #RT-9821',
          time: 'Sep 01',
        ),
        const _ActivityItem(
          icon: Icons.handyman,
          title: 'Maintenance Scheduled',
          subtitle: 'Technician: Mark S.',
          time: 'Yesterday',
        ),
        const _ActivityItem(
          icon: Icons.campaign,
          title: 'Building Announcement',
          subtitle: 'Elevator B maintenance',
          time: '2d ago',
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(icon, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Text(time, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
