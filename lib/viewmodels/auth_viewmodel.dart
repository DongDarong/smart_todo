import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  AuthViewModel() {
    user = _auth.currentUser;
  }

  Future<String?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = result.user;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = result.user;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    try {
      // Also sign out of Google if used
      await GoogleSignIn().signOut();
    } catch (_) {}
    user = null;
    notifyListeners();
  }

  String? get uid => user?.uid;

  /// Sign in using Google account. Supports web and mobile.
  Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        user = userCredential.user;
        notifyListeners();
        return null;
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return 'Sign-in cancelled';
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await _auth.signInWithCredential(credential);
        user = result.user;
        notifyListeners();
        return null;
      }
    } catch (e) {
      return e.toString();
    }
  }

  /// Link the currently signed-in Firebase user with Google credential.
  Future<String?> linkWithGoogle() async {
    try {
      if (user == null) return 'No signed-in user to link';
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final result = await user!.linkWithPopup(googleProvider);
        user = result.user;
        notifyListeners();
        return null;
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return 'Sign-in cancelled';
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await user!.linkWithCredential(credential);
        user = result.user;
        notifyListeners();
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  /// Unlink Google provider from the currently signed-in user.
  Future<String?> unlinkGoogle() async {
    try {
      if (user == null) return 'No signed-in user to unlink';
      await user!.unlink('google.com');
      // Refresh user
      user = _auth.currentUser;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }
}
