import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 6),
            Text(
              'Hi, Alex Fletcher 👋',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Row(
          children: const [
            Icon(Icons.notifications_none),
            SizedBox(width: 12),
            CircleAvatar(radius: 18),
          ],
        )
      ],
    );
  }
}
