import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/presentation/screens/auth/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(create: (_) => AuthProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chak Property System',
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().loggedIn;
    if (loggedIn) {
      return const Scaffold(body: Center(child: Text('Logged in')));
    } else {
      return const LoginPage();
    }
  }
}