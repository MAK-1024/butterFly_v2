import 'dart:async';

import 'package:butterfly_v2/features/orders/presentation/views/states/PurchasedScreen.dart';
import 'package:butterfly_v2/features/orders/presentation/views/states/ReservationsScreen.dart';
import 'package:butterfly_v2/features/orders/presentation/views/states/forDelievryScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_router/routes.dart';
import '../widgets/drawer.dart';
import 'states/ArabeenScreen.dart';
import 'states/DeliveredScreen.dart';
import 'states/ReadyScreen.dart';

class MainOrderScreen extends StatefulWidget {
  final List<String> userRoles;

  const MainOrderScreen({super.key, required this.userRoles});

  @override
  State<MainOrderScreen> createState() => _MainOrderScreenState();
}

class _MainOrderScreenState extends State<MainOrderScreen> {
  int _selectedIndex = 0;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  List<Widget> _screens = [];
  List<String> _titles = [];
  List<IconData> _icons = [];
  List<String> _currentRoles = [];

  @override
  void initState() {
    super.initState();

    _buildScreensForRoles(widget.userRoles);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _userDocSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) return;
        final data = snapshot.data()!;

        // Handle force logout
        if (data['forceLogout'] == true) {
          FirebaseAuth.instance.signOut();
          if (mounted) {
            GoRouter.of(context).go(AppRouter.loginScreen);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('تم تسجيل الخروج إجباريًا من قبل المسؤول')),
            );
          }
          return;
        }

        final roleData = data['role'];
        List<String> roles = [];
        if (roleData is String) {
          roles = [roleData];
        } else if (roleData is List) {
          roles = roleData.map((e) => e.toString()).toList();
        } else {
          roles = ['user'];
        }

        if (mounted) {
          setState(() {
            _currentRoles = roles;
            _buildScreensForRoles(roles);
          });
        }
      });
    }
  }

  void _buildScreensForRoles(List<String> roles) {
    _screens = [];
    _titles = [];
    _icons = [];

    if (roles.contains('admin')) {
      _screens.addAll([
        ArabeenScreen(userRoles: roles),
        ReservationsScreen(userRoles: roles),
        PurchasedScreen(userRoles: roles),
        ReadyScreen(userRoles: roles),
        ForDelievryScreen(userRoles: roles),
        DeliveredScreen(userRoles: roles),
      ]);
      _titles.addAll([
        'العرابين',
        'الحجوزات',
        'تم الشراء',
        'الجاهزة',
        'التوصيل',
        'المسلمة'
      ]);
      _icons.addAll([
        Icons.assignment,
        Icons.bookmark_border,
        Icons.shopping_cart,
        Icons.local_shipping,
        Icons.delivery_dining,
        Icons.done_all,
      ]);
    }

    if (roles.contains('manager')) {
      _screens.addAll([
        ArabeenScreen(userRoles: roles),
        ReservationsScreen(userRoles: roles),
        PurchasedScreen(userRoles: roles),
        ReadyScreen(userRoles: roles),
        DeliveredScreen(userRoles: roles),
      ]);
      _titles
          .addAll(['العرابين', 'الحجوزات', 'تم الشراء', 'الجاهزة', 'المسلمة']);
      _icons.addAll([
        Icons.assignment,
        Icons.bookmark_border,
        Icons.shopping_cart,
        Icons.local_shipping,
        Icons.done_all,
      ]);
    }

    if (roles.contains('user')) {
      _screens.addAll([
        ArabeenScreen(userRoles: roles),
        ReservationsScreen(userRoles: roles),
      ]);
      _titles.addAll(['العرابين', 'الحجوزات']);
      _icons.addAll([Icons.assignment, Icons.bookmark_border]);
    }

    if (roles.contains('coordinator')) {
      _screens.addAll(
          [ ReadyScreen(userRoles: roles) , ForDelievryScreen(userRoles: roles),
           ]);
      _titles.addAll([
        'الجاهزة',
        'التوصيل',

      ]);
      _icons.addAll([
        Icons.delivery_dining,
        Icons.local_shipping,
      ]);
    }

    // if ( roles.contains('coordinator')) {
    //   _screens.add(ReadyScreen(userRoles: roles));
    //   _titles.add('الجاهزة');
    //   _icons.add(Icons.local_shipping);
    // }

    if (roles.contains('delivery')) {
      _screens.add(ForDelievryScreen(userRoles: roles));
      _titles.add('التوصيل');
      _icons.add(Icons.delivery_dining);
    }
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            if (_currentRoles.contains('admin') ||
                _currentRoles.contains('manager'))
              IconButton(
                onPressed: () {
                  GoRouter.of(context).push(AppRouter.allOrdersScreen);
                },
                icon: const Icon(Icons.search),
              )
          ],
        ),
        drawer: const AppDrawer(),
        body: _screens.isNotEmpty
            ? _screens[_selectedIndex]
            : Center(child: Text('لا يوجد صلاحيات مناسبة')),
        bottomNavigationBar: _screens.length > 1
            ? BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onTabTapped,
                type: BottomNavigationBarType.shifting,
                selectedItemColor: Colors.black,
                unselectedItemColor: Colors.grey,
                items: List.generate(
                  _titles.length,
                  (index) => BottomNavigationBarItem(
                    icon: Icon(_icons[index]),
                    label: _titles[index],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
