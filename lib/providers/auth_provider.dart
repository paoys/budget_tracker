// lib/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;
  bool _isLoading = false;

  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuth => _status == AuthStatus.authenticated;
  String? get uid => _user?.uid;
  String? get displayName =>
      _user?.displayName ?? _user?.email?.split('@').first;
  String? get email => _user?.email;
  String? get photoUrl => _user?.photoURL;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      _status =
          user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Email / Password ──────────────────────────────────────────────────────
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerWithEmail(
      String email, String password, String displayName) async {
    _setLoading(true);
    _setError(null);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await cred.user?.updateDisplayName(displayName.trim());
      await cred.user?.reload();
      _user = _auth.currentUser;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      _setLoading(false);
      return false;
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      if (kIsWeb) {
        // Use web-compatible popup flow
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        _user = userCredential.user;
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _setLoading(false);
          return false;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException code: ${e.code}');
      _setError(_friendlyError(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Google sign-in failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      _setLoading(false);
      return false;
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  Future<bool> updateDisplayName(String name) async {
    try {
      await _user?.updateDisplayName(name.trim());
      await _user?.reload();
      _user = _auth.currentUser;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
