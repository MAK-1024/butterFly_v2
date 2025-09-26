  import 'package:butterfly_v2/features/auth/presentation/pages/login_screen.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:go_router/go_router.dart';

  import '../../features/auth/presentation/widgets/auth_state_listener.dart';
  import '../../features/orders/data/dataSource/order_data_source.dart';
  import '../../features/orders/data/model/orderModel.dart';
  import '../../features/orders/presentation/cubit/orders_cubit.dart';
  import '../../features/orders/presentation/views/AddOrderScreen.dart';
  import '../../features/orders/presentation/views/MainOrderScreen.dart';
  import '../../features/orders/presentation/views/all_orders.dart';
  import '../../features/orders/presentation/views/currency.dart';
  import '../../features/orders/presentation/views/detailsForDelievry.dart';
import '../../features/orders/presentation/views/detailsScreen2.dart';

  abstract class AppRouter {
    static const String authStateListener = "/";
    static const String mainOrderScreen = "/mainOrderScreen";
    static const String orderDetailsScreen = "/orderDetails";
    static const String currencyConverterScreen = "/currencyConverter";
    static const String addOrderScreen = "/addOrder";
    static const String allOrdersScreen = "/allOrdersScreen";
    static const String loginScreen = "/loginScreen";
    static const String detailsForDelievry = "/detailsForDelievry";


    static final _rootNavigatorKey = GlobalKey<NavigatorState>();

    static final router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: authStateListener,
      routes: [
        GoRoute(
          path: authStateListener,
          builder: (context, state) =>  AuthStateListener(),
        ),
        GoRoute(
          path: mainOrderScreen,
          builder: (context, state) {
            final userRoles = state.extra as List<String>? ?? ['user'];
            return MainOrderScreen(userRoles: userRoles);
          },
        ),

        GoRoute(
          path: loginScreen,
          builder: (context, state) =>  LoginScreen(),
        ),



        GoRoute(
          path: allOrdersScreen,
          builder: (context, state) =>  AllOrdersScreen(),
        ),
        GoRoute(
          path: orderDetailsScreen,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            final order = extra['order'] as OrderModel;
            final userRoles = extra['userRoles'] as List<String>;

            return BlocProvider(
              create: (context) =>
                  OrderCubit(OrderRemoteDataSource(FirebaseFirestore.instance)),
              child: OrderDetailsScreen2(
                order: order,
                userRoles: userRoles,
              ),
            );
          },
        ),

        GoRoute(
          path: detailsForDelievry,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            final order = extra['order'] as OrderModel;

            return BlocProvider(
              create: (context) =>
                  OrderCubit(OrderRemoteDataSource(FirebaseFirestore.instance)),
              child: DetailsForDelievry(
                order: order,
              ),
            );
          },
        ),
        GoRoute(
          path: currencyConverterScreen,
          builder: (context, state) =>  CurrencyConverterScreen(),
        ),
        GoRoute(
          path: addOrderScreen,
          builder: (context, state) => AddOrderScreen(),
        ),

      ],
    );

    // Keeping all your navigation methods exactly the same
    static void goToMainOrderScreen(BuildContext context, String userRole) {
      context.push('$mainOrderScreen?role=$userRole');
    }

    static Future<T?> goToOrderDetails<T>(
        BuildContext context, {
          required OrderModel order,
          required List<String> userRoles,
        }) {
      return context.push<T>(
        orderDetailsScreen,
        extra: {
          'order': order,
          'userRoles': userRoles,
        },
      );
    }

    static Future<T?> goToOrderDetails2<T>(
        BuildContext context, {
          required OrderModel order,
        }) {
      return context.push<T>(
        detailsForDelievry,
        extra: {
          'order': order,
        },
      );
    }



    static void goToCurrencyConverter(BuildContext context) {
      context.push(currencyConverterScreen);
    }

    static void goToAddOrderScreen(BuildContext context, OrderModel order) {
      context.push(addOrderScreen, extra: order);
    }

    static void goAllOrdersScreen(BuildContext context) {
      context.push(allOrdersScreen);
    }
  }