import 'package:flutter/material.dart';

class ApplicationPage extends StatelessWidget {
  final String propertyId;

  const ApplicationPage({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Property'),
      ),
      body: Center(
        child: Text(
          'Application page for property:\n$propertyId',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
