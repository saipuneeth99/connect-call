import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/errors/app_exception.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId:
                  '877726576292-036tptn29iea5jv3ou8i4g5mav5k7ojo.apps.googleusercontent.com',
            );

  @override
  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _mapFirebaseUser(credential.user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<AppUser?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name.trim());
        await user.reload();
        return _mapFirebaseUser(_auth.currentUser);
      }
      return _mapFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return _mapFirebaseUser(userCredential.user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return _mapFirebaseUser(_auth.currentUser);
  }

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map(_mapFirebaseUser);

  AppUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      name: user.displayName?.isNotEmpty == true
          ? user.displayName!
          : (user.email?.split('@').first ?? 'User'),
      email: user.email ?? '',
      avatarUrl: user.photoURL,
      isOnline: true,
      lastSeen: DateTime.now(),
    );
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email address.';
      case 'wrong-password':
        return 'Incorrect password provided.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}
