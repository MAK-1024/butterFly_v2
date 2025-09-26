import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/app_router/routes.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/pages/admin.dart';
import '../../../auth/presentation/pages/admin_panal.dart';
import '../views/all_orders.dart';


class AppDrawer extends StatelessWidget {


  const AppDrawer(
      {Key? key,})
      : super(key: key);


  Future<bool> checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userDoc.exists && userDoc.data()?['role'] == 'admin';
  }
  Future<bool> checkUserRole2() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userDoc.exists && userDoc.data()?['role'] == 'admin' || userDoc.exists && userDoc.data()?['role'] == 'user' || userDoc.exists && userDoc.data()?['role'] == 'manager';
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(user),
            // _buildListTile(
            //   icon: Icons.inventory_2_outlined,
            //   text: "جميع الطلبات",
            //   onTap: () {
            //     Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //             builder: (context) => AllOrdersScreen()));
            //   },
            // ),
            FutureBuilder<bool>(
              future: checkUserRole(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }
                if (snapshot.hasData && snapshot.data == true) {
                  return _buildListTile(
                    icon: Icons.admin_panel_settings_outlined,
                    text: " الحسابات",
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AdminPanal()));
                    },
                  );
                }
                return const SizedBox();
              },
            ),


            _buildListTile(
              icon: Icons.calculate_outlined,
              text: "تحويل العملات",
              onTap: () {
                GoRouter.of(context).push(AppRouter.currencyConverterScreen);
              },
            ),
            // FutureBuilder<bool>(
            //   future: checkUserRole(),
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.waiting) {
            //       return const SizedBox();
            //     }
            //     if (snapshot.hasData && snapshot.data == true) {
            //       return _buildListTile(
            //         icon: Icons.admin_panel_settings_outlined,
            //         text: "انشاء الحسابات",
            //         onTap: () {
            //           Navigator.push(
            //               context,
            //               MaterialPageRoute(
            //                   builder: (context) => AdminScreen()));
            //         },
            //       );
            //     }
            //     return const SizedBox();
            //   },
            // ),

            // FutureBuilder<bool>(
            //   future: checkUserRole2(),
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.waiting) {
            //       return const SizedBox();
            //     }
            //     if (snapshot.hasData && snapshot.data == true) {
            //       return _buildListTile(
            //         icon: Icons.inventory_2_outlined,
            //         text: "جميع الطلبات",
            //         onTap: () {
            //           Navigator.push(
            //               context,
            //               MaterialPageRoute(
            //                   builder: (context) => AllOrdersScreen()));
            //         },
            //       );
            //     }
            //     return const SizedBox();
            //   },
            // ),

            const Divider(),

            _buildListTile(
              icon: Icons.logout,
              text: "تسجيل الخروج",
              onTap: () async {
                final bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context){
                      return     AlertDialog(
                        title: Text("تأكيد تسجيل الخروج"),
                        content: Text("هل أنت متأكد من تسجيل الخروج؟"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text("إلغاء"),
                          ),
                          TextButton(
                            onPressed: () async {
                              await context.read<AuthCubit>().signOut();
                              if (context.mounted) {
                                GoRouter.of(context).go(AppRouter.loginScreen);
                              }
                              toastification.show(
                                type: ToastificationType.success,
                                context: context,
                                title: Text('تم تسجيل الخروج بنجاح'),
                                autoCloseDuration: Duration(seconds: 5),
                              );
                            },
                            child: Text("نعم"),
                          )


                        ],
                      );
                    }

                );

              },

            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(color: Colors.white),
      accountName: Text(
        user?.displayName ?? "حساب المستخدم",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      accountEmail: Text(
        user?.email ?? "البريد الإلكتروني",
        style: TextStyle(color: Colors.black54),
      ),
      currentAccountPicture: const CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.person, size: 40, color: Colors.black),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String text,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(text, style: TextStyle(color: Colors.black, fontSize: 16)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.black54))
          : null,
      onTap: onTap,
    );
  }

  Future<bool?> _showLogoutConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد تسجيل الخروج"),
        content: const Text("هل أنت متأكد أنك تريد تسجيل الخروج؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("تسجيل الخروج"),
          ),
        ],
      ),
    );
  }

// Widget _buildThemeToggle(BuildContext context, bool isDark) {
//   return ListTile(
//     leading: Icon(Icons.brightness_6, color: isDark ? Colors.white : Colors.black),
//     title: Text("الوضع الليلي", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16)),
//     onTap: () => AdaptiveTheme.of(context).toggleThemeMode(),
//   );
// }
}
