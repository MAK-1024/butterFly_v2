import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/themes/roles.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repo.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  UserModel? _currentUser;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    _initAuthListener();
  }

  // =================== Auth Listener ===================

  void _initAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
      if (isClosed) return; // Prevents emitting after close
      if (firebaseUser != null) {
        await loadCurrentUser(firebaseUser.uid);
      } else {
        _currentUser = null;
        if (!isClosed) emit(AuthUnauthenticated());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }


  // =================== Sign Up ===================
  Future<void> signUp({
    required String email,
    required String password,
    required List<String> roles, // updated
    String? name,
    String? phone,
  }) async {
    try {
      emit(AuthLoading());

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = UserModel(
        id: credential.user!.uid,
        email: email,
        role: roles,
        userName: name,
        phone: phone,
      );

      await _firestore.collection('users').doc(user.id).set(user.toMap());

      await loadCurrentUser(user.id);
    } catch (e) {
      emit(AuthError('Signup failed: ${e.toString()}'));
      rethrow;
    }
  }

  // =================== Sign In ===================
  Future<void> signIn(String email, String password) async {
    if (isClosed) return;
    emit(AuthLoading());

    try {
      final userModel = await _authRepository.signIn(email, password);
      if (userModel != null) {
        _currentUser = userModel; // ✅ store fresh user
        emit(AuthAuthenticated(_currentUser!));
      } else {
        emit(AuthError('Login failed: user not found'));
      }
    } catch (e) {
      if (!isClosed) emit(AuthError('Login failed: ${e.toString()}'));
      rethrow;
    }
  }


  Future<void> toggleForceLogoutUser(String userId) async {
    try {
      emit(AuthLoading());

      final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        emit(AuthError('المستخدم غير موجود'));
        return;
      }

      final currentStatus = docSnapshot.data()?['forceLogout'] ?? false;

      // Toggle the forceLogout flag
      await docRef.update({
        'forceLogout': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload the latest user list from Firestore
      final updatedUsersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final updatedUsers = updatedUsersSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // If you had filtering logic, re-apply it here
      _filteredUsers = updatedUsers; // or your filtering function

      emit(AuthUsersLoaded(_filteredUsers));

    } catch (e) {
      emit(AuthError('فشل في تحديث حالة تسجيل الخروج الإجباري: ${e.toString()}'));
    }
  }


  // =================== Sign Out ===================
  Future<void> signOut() async {
    if (isClosed) return;
    emit(AuthLoading());
    _currentUser = null;
    _users = [];
    _filteredUsers = [];
    await _authRepository.signOut();
    emit(AuthUnauthenticated());
  }
// =================== Reset Password ===================
  Future<void> resetPassword(String email) async {
    try {
      emit(AuthLoading());
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      emit(AuthPasswordResetSent());
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'البريد الإلكتروني غير مسجل';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صالح';
      } else {
        message = 'حدث خطأ أثناء إعادة التعيين';
      }
      emit(AuthError(message));
    }
  }

  // =================== Load Current User ===================
  Future<void> loadCurrentUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, doc.id);

        if (_currentUser!.isDisabled) {
          await signOut();
          emit(AuthError('This account is disabled'));
        } else {
          emit(AuthAuthenticated(_currentUser!));
        }
      } else {
        await signOut();
        emit(AuthError('User data not found'));
      }
    } catch (e) {
      await signOut();
      emit(AuthError('Failed to load user data: ${e.toString()}'));
    }
  }

  // =================== Fetch All Users ===================
  Future<void> fetchUsers() async {
    try {
      emit(AuthLoading());
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      _users = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()!, doc.id))
          .toList();

      _filteredUsers = List.from(_users);
      emit(AuthUsersLoaded(_filteredUsers));
    } catch (e) {
      emit(AuthError('Failed to load users: ${e.toString()}'));
    }
  }

  // =================== Search Users ===================
  void searchUsers(String query) {
    _filteredUsers = _users.where((user) {
      return user.email.toLowerCase().contains(query.toLowerCase()) ||
          (user.userName?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (user.phone?.contains(query) ?? false);
    }).toList();
    emit(AuthUsersLoaded(_filteredUsers));
  }

  // =================== Toggle User Activation ===================
  Future<void> toggleUserStatus(String userId, bool isDisabled) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isDisabled': isDisabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _users = _users.map((user) =>
      user.id == userId ? user.copyWith(isDisabled: isDisabled) : user).toList();
      _filteredUsers = List.from(_users);

      if (_currentUser?.id == userId && isDisabled) {
        await signOut();
      } else {
        emit(AuthUsersLoaded(_filteredUsers));
      }
    } catch (e) {
      emit(AuthError('Failed to update user status: ${e.toString()}'));
    }
  }

  // =================== Update Roles ===================
  Future<void> updateUserRoles(String userId, List<String> newRoles) async {
    try {
      for (var role in newRoles) {
        if (!AppRoles.allRoles.contains(role)) {
          throw Exception('Invalid role: $role');
        }
      }

      await _firestore.collection('users').doc(userId).update({
        'role': newRoles,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _users = _users.map((user) =>
      user.id == userId ? user.copyWith(role: newRoles) : user).toList();
      _filteredUsers = List.from(_users);

      if (_currentUser?.id == userId) {
        await loadCurrentUser(userId);
      } else {
        emit(AuthUsersLoaded(_filteredUsers));
      }
    } catch (e) {
      emit(AuthError('Failed to update user roles: ${e.toString()}'));
    }
  }


  void clearRoles() {
    _currentUser = null;
    emit(AuthInitial());
  }



  // =================== Getters ===================
  UserModel? get currentUser => _currentUser;

  String? get currentUserId => _currentUser?.id;

  List<String> get currentUserRoles => _currentUser?.role ?? [];

  bool get isAdmin => _currentUser?.role.contains(AppRoles.admin) ?? false;
  bool get isCoordinator => _currentUser?.role.contains(AppRoles.coordinator) ?? false;
  bool get isDelivery => _currentUser?.role.contains(AppRoles.delivery) ?? false;
  bool get isRegularUser => _currentUser?.role.contains(AppRoles.user) ?? false;
}
