// import 'dart:math';
//
// import 'package:butterfly_v2/features/orders/presentation/cubit/roles_state.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class UserRoleCubit extends Cubit<UserRoleState> {
//   UserRoleCubit() : super(UserRoleInitial());
//
//   Future<void> fetchUserRole() async {
//     emit(UserRoleLoading());
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         emit(UserRoleError("No user is logged in"));
//         return;
//       }
//
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
//
//       final role = doc.get('role');
//       print(role);
//       emit(UserRoleLoaded(role));
//     } catch (e) {
//       emit(UserRoleError("Failed to fetch user role: $e"));
//     }
//   }
//
//   bool isRole(String requiredRole) {
//     if (state is UserRoleLoaded) {
//       return (state as UserRoleLoaded).role == requiredRole;
//     }
//     return false;
//   }
// }
