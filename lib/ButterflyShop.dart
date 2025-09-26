import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/app_router/routes.dart';
import 'core/constants/build_networkError.dart';
import 'features/auth/data/datasources/auth_data_source.dart';
import 'features/auth/data/repositories/auth_repo.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/orders/data/dataSource/order_data_source.dart';
import 'features/orders/presentation/cubit/bulk_cubit.dart';
import 'features/orders/presentation/cubit/orders_cubit.dart';
import 'features/orders/presentation/cubit/roles_cubit.dart';

class ButterflyShop extends StatefulWidget {
  const ButterflyShop({super.key});

  @override
  State<ButterflyShop> createState() => _ButterflyShopState();
}

class _ButterflyShopState extends State<ButterflyShop> {
  final NetworkErrorManager _networkManager = NetworkErrorManager();

  @override
  void initState() {
    super.initState();
    _networkManager.initialize();
  }

  @override
  void dispose() {
    _networkManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      child: ValueListenableBuilder(
        valueListenable: _networkManager.connectionStatusNotifier,
        builder: (context, status, _) {
          final isConnected = _networkManager.isConnected;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => OrderCubit(
                      OrderRemoteDataSource(FirebaseFirestore.instance)),
                ),
                BlocProvider(create: (_) => BulkCubit()),
                // BlocProvider(create: (_) => UserRoleCubit()),
                BlocProvider(
                  create: (context) => AuthCubit(
                    AuthRepository(AuthDataSource(FirebaseAuth.instance,FirebaseFirestore.instance)), // Your auth repository implementation
                  ),
                ),
              ],
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: AppRouter.router,
                builder: (context, child) {
                  return isConnected
                      ? child ?? const SizedBox.shrink()
                      : _networkManager.buildNoConnectionScreen(() {
                          _networkManager.initialize();
                        });
                },
                theme: ThemeData(
                  fontFamily: GoogleFonts.cairo().fontFamily,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
