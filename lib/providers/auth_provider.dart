import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  fb.FirebaseAuth? _auth;
  bool _firebaseAvailable = false;

  // GoogleSignIn instance (use dynamic to avoid analyzer/API mismatches)
  final dynamic _googleSignIn = GoogleSignIn.instance;
  final AuthRepository? _authRepository;

  fb.User? firebaseUser;
  UserModel? _userProfile;

  AuthProvider([this._authRepository]) {
    _initializeFirebase();
  }

  void _initializeFirebase() {
    try {
      _auth = fb.FirebaseAuth.instance;
      _firebaseAvailable = true;
      _auth!.authStateChanges().listen((u) {
        firebaseUser = u;
        if (u != null) {
          _loadUserProfile();
        }
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
  UserModel? get userProfile => _userProfile;
  bool get isLandlord => _userProfile?.role == UserRole.landlord;
  bool get isTenant => _userProfile?.role == UserRole.tenant;

  Future<void> _loadUserProfile() async {
    if (_authRepository == null || firebaseUser == null) return;
    
    try {
      final result = await _authRepository!.getUserProfile(firebaseUser!.uid);
      result.fold(
        (failure) {
          // Profile doesn't exist yet - this is OK for new users
          debugPrint('User profile not found: ${failure.message}');
          // Don't set _userProfile to null, keep it as is
        },
        (profile) {
          _userProfile = profile;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<String?> signUpWithEmail(
      String name, String email, String password, UserRole role) async {
    if (!_firebaseAvailable || _auth == null) {
      debugPrint('Firebase Auth not available');
      return 'Firebase Authentication is not available. Please try again later.';
    }
    
    try {
      // Create user in Firebase Authentication
      final cred = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name in Firebase Auth
      if (cred.user != null) {
        await cred.user!.updateDisplayName(name);
        await cred.user!.reload();
        firebaseUser = _auth!.currentUser;
      }
      
      // Create user profile in Firestore
      if (firebaseUser != null && _authRepository != null) {
        final userModel = UserModel(
          id: firebaseUser!.uid,
          name: name,
          email: email,
          phone: '',
          role: role,
          createdAt: DateTime.now(),
          isVerified: false,
        );
        final result = await _authRepository!.createUserProfile(userModel);
        result.fold(
          (failure) {
            debugPrint('Failed to create user profile: ${failure.message}');
            // Even if profile creation fails, user is authenticated
            _userProfile = userModel;
            notifyListeners();
          },
          (_) {
            _userProfile = userModel;
            notifyListeners();
          },
        );
      }
      
      notifyListeners();
      return null; // Success
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('signUpWithEmail error: ${e.code} ${e.message}');
      switch (e.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'The email address is invalid.';
        default:
          return e.message ?? 'An error occurred during sign up.';
      }
    } catch (e) {
      debugPrint('signUpWithEmail error: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<String?> signInWithEmail(String email, String password) async {
    if (!_firebaseAvailable || _auth == null) {
      debugPrint('Firebase Auth not available');
      return 'Firebase Authentication is not available. Please try again later.';
    }
    try {
      final cred = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = cred.user;
      
      // Load user profile after successful sign-in
      if (firebaseUser != null) {
        await _loadUserProfile();
      }
      
      notifyListeners();
      return null; // Success
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('signInWithEmail error: ${e.code} ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        default:
          return e.message ?? 'An error occurred during sign in.';
      }
    } catch (e) {
      debugPrint('signInWithEmail error: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Google Sign-In (v7.x)
  Future<String?> signInWithGoogle({UserRole? role}) async {
    if (!_firebaseAvailable || _auth == null) {
      debugPrint('Firebase Auth not available');
      return 'Firebase Authentication is not available. Please try again later.';
    }

    try {
      // Sign in with Google
      final dynamic googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return 'Sign in was cancelled.';
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Ensure we have an ID token (accessToken may not be available in this package/version)
      if (googleAuth.idToken == null) {
        return 'Missing Google ID token.';
      }

      // Create Firebase credential using ID token only
      final credential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final cred = await _auth!.signInWithCredential(credential);
      firebaseUser = cred.user;
      
      // Create or update user profile
      if (firebaseUser != null && _authRepository != null) {
        await _createOrUpdateUserProfileFromOAuth(
          name: firebaseUser!.displayName ?? googleUser.displayName ?? 'User',
          email: firebaseUser!.email ?? googleUser.email,
          role: role,
        );
      }
      
      notifyListeners();
      return null; // Success
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('signInWithGoogle Firebase error: ${e.code} ${e.message}');
      return e.message ?? 'An error occurred during Google sign in.';
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
      if (e.toString().contains('sign_in_canceled') || 
          e.toString().contains('SIGN_IN_CANCELLED')) {
        return 'Sign in was cancelled.';
      }
      return 'An unexpected error occurred during Google sign in.';
    }
  }

  /// Helper method to create or update user profile after OAuth sign-in
  Future<void> _createOrUpdateUserProfileFromOAuth({
    required String name,
    required String email,
    UserRole? role,
  }) async {
    if (firebaseUser == null || _authRepository == null) return;

    try {
      // Check if user profile exists
      final result = await _authRepository!.getUserProfile(firebaseUser!.uid);
      
      result.fold(
        // Profile doesn't exist, create it
        (_) {
          // Use provided role or default to tenant
          final userRole = role ?? UserRole.tenant;
          final userModel = UserModel(
            id: firebaseUser!.uid,
            name: name,
            email: email,
            phone: '',
            role: userRole,
            createdAt: DateTime.now(),
            isVerified: false,
          );
          _authRepository!.createUserProfile(userModel).then((createResult) {
            createResult.fold(
              (failure) => debugPrint('Failed to create profile: ${failure.message}'),
              (_) {
                _userProfile = userModel;
                notifyListeners();
              },
            );
          });
        },
        // Profile exists, load it
        (existingProfile) {
          _userProfile = existingProfile;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error creating/updating user profile: $e');
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
    _userProfile = null;
    notifyListeners();
  }
}
