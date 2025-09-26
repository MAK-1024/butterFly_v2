import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_router/routes.dart';
import '../pages/login_screen.dart';

class AuthStateListener extends StatelessWidget {
  const AuthStateListener({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Handle null user (not authenticated)
        if (!authSnapshot.hasData) {
          // Clear any existing routes and go to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.isCurrent ?? false) {
              context.go(AppRouter.loginScreen);
            }
          });
          return LoginScreen();
        }

        final user = authSnapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              FirebaseAuth.instance.signOut();
              return LoginScreen();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            final roleData = data['role'];
            List<String> userRoles = [];

            if (roleData is String) {
              userRoles = [roleData];
            } else if (roleData is List) {
              userRoles = roleData.map((e) => e.toString()).toList();
            } else {
              userRoles = ['user'];
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(
                AppRouter.mainOrderScreen,
                extra: userRoles,
              );

            });

            return const Scaffold(body: Center(child: CircularProgressIndicator()));

          },
        );
      },
    );
  }
}