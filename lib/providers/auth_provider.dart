import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> sendEmailVerification() async {
    if (_user != null) {
      try {
        await _user!.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        throw FirebaseAuthException(code: e.code, message: e.message);
      }
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await sendEmailVerification();
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (!userCredential.user!.emailVerified) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Por favor verifica tu correo electrónico',
        );
      }
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _googleSignIn.signOut();
      await _auth.signOut();
    } finally {
      _setLoading(false);
    }
  }
}
