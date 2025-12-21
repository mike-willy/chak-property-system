import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
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

  Future<bool> signUpWithEmail(String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await cred.user?.updateDisplayName(name);
      firebaseUser = cred.user;
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('signUpWithEmail error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('signUpWithEmail unknown error: $e');
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      firebaseUser = cred.user;
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('signInWithEmail error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('signInWithEmail unknown error: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;
      final auth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      firebaseUser = cred.user;
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('signInWithGoogle error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('signInWithGoogle unknown error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('signOut error: $e');
    } finally {
      firebaseUser = null;
      notifyListeners();
    }
  }
}