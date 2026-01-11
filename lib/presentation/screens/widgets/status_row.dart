import 'package:flutter/material.dart';
import '../../../core/widgets/common_widgets.dart';

class StatusRow extends StatelessWidget {
  const StatusRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatusCard(
            icon: Icons.build,
            title: 'MAINTENANCE',
            value: '1 Active',
            subtitle: 'Leaky Faucet',
            color: Colors.orange,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatusCard(
            icon: Icons.inventory_2,
            title: 'PACKAGES',
            value: '2 Ready',
            subtitle: 'Main Lobby Desk',
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
