import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/application_form.dart';
import '../../../../providers/auth_provider.dart';

class ApplicationPage extends StatelessWidget {
  final String propertyId;
  final String? unitId;

  const ApplicationPage({
    super.key,
    required this.propertyId,
    this.unitId,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Gatekeeping like a civilized system
    if (!auth.loggedIn) {
      Future.microtask(() {
        Navigator.pushNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('House Application')),
      body: ApplicationForm(
        propertyId: propertyId,
        unitId: unitId,
      ),
    );
  }
}
