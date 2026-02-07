import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository? _authRepository;
  fb.FirebaseAuth? _auth;
  bool _firebaseAvailable = false;

  // Google Sign-In instance
  final dynamic _googleSignIn = GoogleSignIn.instance;

  // Firebase user
  fb.User? firebaseUser;

  // App-specific user profile (from Firestore)
  UserModel? _userProfile;

  AuthProvider([this._authRepository]) {
    _initializeFirebase();
  }

  // ----------------------------
  // Firebase initialization
  // ----------------------------
  void _initializeFirebase() {
    try {
      _auth = fb.FirebaseAuth.instance;
      _firebaseAvailable = true;

      // Listen to auth changes
      _auth!.authStateChanges().listen((user) {
        firebaseUser = user;
        if (user != null) {
          _loadUserProfile();
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
      _firebaseAvailable = false;
    }
  }

  // ----------------------------
  // Getters for UI
  // ----------------------------
  bool get isFirebaseAvailable => _firebaseAvailable;
  bool get loggedIn => firebaseUser != null;
  String? get userId => firebaseUser?.uid;
  String? get userEmail => firebaseUser?.email;
  String? get displayName => firebaseUser?.displayName;
  UserModel? get userProfile => _userProfile;
  bool get isLandlord => _userProfile?.role == UserRole.landlord;
  bool get isTenant => _userProfile?.role == UserRole.tenant;
  bool get isAdmin => _userProfile?.role == UserRole.admin;
  
  // Compatibility getters
  fb.User? get currentUser => firebaseUser;
  String? get UserId => firebaseUser?.uid;
  String? get userRole => _userProfile?.role.value;

  // ----------------------------
  // Load profile from Firestore
  // ----------------------------
  Future<void> _loadUserProfile() async {
    if (_authRepository == null || firebaseUser == null) return;

    try {
      final result = await _authRepository.getUserProfile(firebaseUser!.uid);
      result.fold(
        (failure) {
          debugPrint('User profile not found: ${failure.message}');
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

  // ----------------------------
  // Email/Password Sign-Up
  // ----------------------------
  Future<String?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String phone,
    required String idNumber,
  }) async {
    if (!_firebaseAvailable || _auth == null) {
      return 'Firebase Authentication is not available. Please try again later.';
    }

    try {
      final cred = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
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
          phone: phone,
          role: role,
          createdAt: DateTime.now(),
          isVerified: false,
          idNumber: idNumber,
        );

        final result = await _authRepository.createUserProfile(userModel);
        result.fold(
          (failure) {
            debugPrint('Failed to create user profile: ${failure.message}');
            _userProfile = userModel;
          },
          (_) {
            _userProfile = userModel;
          },
        );

        notifyListeners();
      }

      return null; // success
    } on fb.FirebaseAuthException catch (e) {
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
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // ----------------------------
  // Email/Password Sign-In
  // ----------------------------
  Future<String?> signInWithEmail(String email, String password) async {
    if (!_firebaseAvailable || _auth == null) {
      return 'Firebase Authentication is not available. Please try again later.';
    }

    try {
      final cred = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = cred.user;

      if (firebaseUser != null) {
        await _loadUserProfile();
      }

      notifyListeners();
      return null; // success
    } on fb.FirebaseAuthException catch (e) {
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
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // ----------------------------
  // Google Sign-In
  // ----------------------------
  Future<String?> signInWithGoogle({UserRole? role}) async {
    if (!_firebaseAvailable || _auth == null) {
      return 'Firebase Authentication is not available. Please try again later.';
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Sign in was cancelled.';

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) return 'Missing Google ID token.';

      final credential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final cred = await _auth!.signInWithCredential(credential);
      firebaseUser = cred.user;

      if (firebaseUser != null && _authRepository != null) {
        final error = await _createOrUpdateUserProfileFromOAuth(
          name: firebaseUser!.displayName ?? googleUser.displayName ?? 'User',
          email: firebaseUser!.email ?? googleUser.email,
          role: role,
        );
        
        if (error != null) {
          // If profile creation failed (e.g. Landlord not registered), sign out and return error
          await signOut();
          return error;
        }
      }

      notifyListeners();
      return null;
    } catch (e) {
      if (e.toString().contains('SIGN_IN_CANCELLED')) {
        return 'Sign in was cancelled.';
      }
      return 'An unexpected error occurred during Google sign in.';
    }
  }

  Future<String?> _createOrUpdateUserProfileFromOAuth({
    required String name,
    required String email,
    UserRole? role,
  }) async {
    if (firebaseUser == null || _authRepository == null) return 'Auth not initialized';

    try {
      final result = await _authRepository.getUserProfile(firebaseUser!.uid);
      
      // Use a Completer or local variable to extract the return value from the Either fold
      String? returnError;
      
      await result.fold(
        (_) async {
          // User does not exist
          
          // CRITICAL: Landlords must be registered by Admin. 
          // Do not create a new profile if the intended role is Landlord.
          if (role == UserRole.landlord) {
            returnError = 'Landlord account not found. Please contact an administrator.';
            return;
          }

          final userRole = role ?? UserRole.tenant;
          final userModel = UserModel(
            id: firebaseUser!.uid,
            name: name,
            email: email,
            phone: '',
            role: userRole,
            createdAt: DateTime.now(),
            isVerified: false,
            idNumber: '', 
          );
          final createResult = await _authRepository.createUserProfile(userModel);
          createResult.fold(
            (failure) {
               debugPrint('Failed to create profile: ${failure.message}');
               returnError = failure.message;
            },
            (_) {
              _userProfile = userModel;
              notifyListeners();
              returnError = null;
            },
          );
        },
        (existingProfile) async {
          _userProfile = existingProfile;
          notifyListeners();
          returnError = null;
        },
      );
      
      return returnError;
    } catch (e) {
      debugPrint('Error creating/updating user profile: $e');
      return 'An unexpected error occurred.';
    }
  }

  // ----------------------------
  // Sign-Out
  // ----------------------------
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
