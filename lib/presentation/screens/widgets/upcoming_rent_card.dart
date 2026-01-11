import 'package:flutter/material.dart';
import '../../../core/widgets/common_widgets.dart';

class UpcomingRentCard extends StatelessWidget {
  const UpcomingRentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_month, color: Colors.blue),
              SizedBox(width: 8),
              Text('Upcoming Rent',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\$2,450.00',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Due on Oct 1st, 2023',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Pay Now'),
              )
            ],
          ),
        ],
      ),
    );
  }
}
