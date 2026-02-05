import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    user = null;
    notifyListeners();
  }

  String? get uid => user?.uid;
}
