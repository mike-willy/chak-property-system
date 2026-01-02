import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  fb.FirebaseAuth? _auth;
  bool _firebaseAvailable = false;

  // v7.x: singleton only
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  fb.User? firebaseUser;

  AuthProvider() {
    _initializeFirebase();
  }

  void _initializeFirebase() {
    try {
      _auth = fb.FirebaseAuth.instance;
      _firebaseAvailable = true;
      _auth!.authStateChanges().listen((u) {
        firebaseUser = u;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
      _firebaseAvailable = false;
    }
  }

  bool get isFirebaseAvailable => _firebaseAvailable;

  bool get loggedIn => firebaseUser != null;
  String? get userEmail => firebaseUser?.email;
  String? get displayName => firebaseUser?.displayName;

  Future<bool> signUpWithEmail(
      String name, String email, String password) async {
    if (!_firebaseAvailable || _auth == null) {
      debugPrint('Firebase Auth not available');
      return false;
    }
    try {
      final cred = await _auth!.createUserWithEmailAndPassword(
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
    } catch (e) {
      debugPrint('signUpWithEmail error: $e');
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    if (!_firebaseAvailable || _auth == null) {
      debugPrint('Firebase Auth not available');
      return false;
    }
    try {
      final cred = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = cred.user;
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('signInWithEmail error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('signInWithEmail error: $e');
      return false;
    }
  }

  /// Google Sign-In (v7.x)
  Future<bool> signInWithGoogle() async {
    if (!_firebaseAvailable || _auth == null) {
      debugPrint('Firebase Auth not available');
      return false;
    }
    try {
      // Initialize Google Sign-In if needed
      await _googleSignIn.initialize();
      
      // Use signIn() method instead of authenticate()
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return false;
      }
      
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      // Create Firebase credential with both tokens
      final credential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Sign in to Firebase
      final cred = await _auth!.signInWithCredential(credential);
      firebaseUser = cred.user;
      notifyListeners();
      return true;
    } catch (e) {
      // User cancelled or sign-in failed
      debugPrint('signInWithGoogle error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    if (_firebaseAvailable && _auth != null) {
      try {
        await _auth!.signOut();
      } catch (e) {
        debugPrint('Firebase signOut error: $e');
      }
    }
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google signOut error: $e');
    }
    firebaseUser = null;
    notifyListeners();
  }
}