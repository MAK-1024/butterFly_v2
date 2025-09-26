import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../../../../../core/app_router/routes.dart';
import '../../../../../core/constants/card_widget.dart';
import '../../../data/model/orderModel.dart';
import '../../cubit/OrderDetailsCubit.dart';
import '../../cubit/orders_cubit.dart';
import '../../cubit/orders_state.dart';
import '../detailsScreen2.dart';

class ArabeenScreen extends StatefulWidget {
  final List<String> userRoles;

  const ArabeenScreen({super.key, required this.userRoles});

  @override
  State<ArabeenScreen> createState() => _ArabeenScreenState();
}

class _ArabeenScreenState extends State<ArabeenScreen> {
  String uu = 'موظف';

  @override
  void initState() {
    _fetchUserData();
    super.initState();
    context.read<OrderCubit>().loadOrdersByStatus(OrderStatus.pending);
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          uu = user.displayName ?? "موظف";
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRoles = widget.userRoles;

    return Scaffold(
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderFailure) {

            print(state.message);
          }
          if (state is OrderOperationSuccess) {


          }
        },
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل الطلبات...'),
                ],
              ),
            );
          }

          if (state is OrderFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('حدث خطأ: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<OrderCubit>().loadOrdersByStatus(
                            context.read<OrderCubit>().currentFilter ??
                                OrderStatus.pending,
                          );
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (state is OrdersLoaded) {
            final orders = state.orders;

            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list, size: 100, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "لا توجد طلبات عرابين حتى الآن.",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: OrderCard(
                    orderId: order.id,
                    emName: order.userName,
                    userName: order.customerName,
                    customerPhone: order.customerNumber,
                    createdAt: order.createdAt,
                    status: order.statusArabic,
                    pieces: order.pieceCount,
                    deposit: order.deposit,
                    totalPrice: order.totalPrice,
                    statusColor: order.statusColor,
                    linkedOrderIds: order.linkedOrderIds,
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider<OrderDetailsCubit>(
                            create: (_) => OrderDetailsCubit(),
                            child: OrderDetailsScreen2(
                              order: order,
                              userRoles: userRoles,
                            ),
                          ),
                        ),
                      );                   },
                  ),
                );
              },
            );          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          GoRouter.of(context).push(AppRouter.addOrderScreen);
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
