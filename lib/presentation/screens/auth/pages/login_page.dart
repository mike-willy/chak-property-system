import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => loading = true);

    final success = await context.read<AuthProvider>().signInWithEmail(email, password);

    if (!mounted) return;
    setState(() => loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in')));
      // Navigation is handled automatically by AuthGate listening to AuthProvider
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in failed')));
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => loading = true);
    final success = await context.read<AuthProvider>().signInWithGoogle();
    if (!mounted) return;
    setState(() => loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in with Google')));
      // Navigation is handled automatically by AuthGate listening to AuthProvider
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign in cancelled or failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (v) => email = v?.trim() ?? '',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onSaved: (v) => password = v ?? '',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter password';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                loading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Sign in'),
                        ),
                      ),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('or')), Expanded(child: Divider())]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                onPressed: loading ? null : _googleSignIn,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage())),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}