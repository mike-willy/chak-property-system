import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  // v7.x: singleton only
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  fb.User? firebaseUser;

  AuthProvider() {
    _auth.authStateChanges().listen((u) {
      firebaseUser = u;
      notifyListeners();
    });
  }

  bool get loggedIn => firebaseUser != null;
  String? get userEmail => firebaseUser?.email;
  String? get displayName => firebaseUser?.displayName;

  Future<bool> signUpWithEmail(
      String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      firebaseUser = cred.user;
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('signUpWithEmail error: ${e.code} ${e.message}');
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = cred.user;
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('signInWithEmail error: ${e.code} ${e.message}');
      return false;
    }
  }

  /// Google Sign-In (v7.x)
  Future<bool> signInWithGoogle() async {
  try {
    await _googleSignIn.initialize();

    final account = await _googleSignIn.authenticate();

    final auth = await account.authentication;
    final credential = fb.GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

    

    final cred = await _auth.signInWithCredential(credential);
    firebaseUser = cred.user;
    notifyListeners();
    return true;
  } catch (e) {
    debugPrint('signInWithGoogle error: $e');
    return false;
  }
}

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    firebaseUser = null;
    notifyListeners();
  }
}
