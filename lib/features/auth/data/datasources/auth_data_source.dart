import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthDataSource(this._firebaseAuth, this._firestore);

  Future<User?> signInWithEmailPassword(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  Future<UserModel?> fetchUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection('users1').doc(uid).get();
      if (doc.exists) {
        print('Fetched user: ${doc.data()}'); // Debugging line
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');  // Print the error
      return null;
    }
  }






  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
