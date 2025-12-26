import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/presentation/screens/auth/pages/login_page.dart';
import 'package:mobile_app/presentation/screens/pages/dashboard_page.dart';
import 'package:mobile_app/presentation/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to initialize Firebase, but continue even if it fails
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('App will continue without Firebase (some features may be limited)');
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chak Property System',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Wait a brief moment for Firebase auth to initialize
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading indicator while initializing
        if (_isInitializing) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Navigate based on authentication state
        if (authProvider.loggedIn) {
          return const DashboardPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}