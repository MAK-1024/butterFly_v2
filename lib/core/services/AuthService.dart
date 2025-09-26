import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/data/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserModel?> get userStream {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required List<String> roles, // <-- change here
    String? name,
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        id: credential.user!.uid,
        email: email,
        role: roles,  // assign list here
        userName: name,
        phone: phone,
      );

      await _firestore.collection('users').doc(user.id).set(user.toMap());

      return user;
    } catch (e) {
      throw FirebaseAuthException(code: 'signup-failed', message: e.toString());
    }
  }


  Future<UserModel?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
      if (!doc.exists) throw Exception('User document not found');

      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw FirebaseAuthException(code: 'login-failed', message: e.toString());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}