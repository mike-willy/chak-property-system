import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/presentation/themes/theme_colors.dart';
import '../pages/login_page.dart';
import '../../pages/dashboard_page.dart';

class AuthGate extends StatefulWidget {
  final Widget? child;

  const AuthGate({super.key, this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // Give Firebase Auth a moment to initialize and check auth state
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading while initializing or checking auth state
        if (_isInitializing || !authProvider.isFirebaseAvailable) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, show the app
        if (authProvider.loggedIn) {
          return widget.child ?? const DashboardPage();
        }

        // If user is not logged in, show login page
        return const LoginPage();
      },
    );
  }
}
