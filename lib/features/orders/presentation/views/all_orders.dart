import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/app_router/routes.dart';
import '../../../../core/constants/card_widget.dart';
import '../../data/model/CompletedGroupModel.dart';
import '../../data/model/orderModel.dart';
import '../cubit/OrderDetailsCubit.dart';
import '../cubit/bulk_cubit.dart';
import '../cubit/bulk_state.dart';
import 'detailsScreen2.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedStatus = 'الكل';
  final List<String> userRoles = [];
  String uu = 'موظف';
  void initState() {
    _fetchUserData();
    super.initState();
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

  final List<String> statusFilters = [
    'الكل',
    'عرابين',
    'حجوزات',
    'تم الشراء',
    'جاهزة',
    'توصيل',
    'مسلمة',
  ];

  @override
  Widget build(BuildContext context) {
    // Get bulk folders from BulkCubit state once per build
    final bulkState = context.read<BulkCubit>().state;
    List<BulkFolder> bulkFolders = [];
    if (bulkState is BulkLoaded) {
      bulkFolders = bulkState.bulks;
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('جميع الطلبات')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن اسم أو رقم أو مستخدم',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30))),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value.trim().toLowerCase());
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: statusFilters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final label = statusFilters[index];
                        return ChoiceChip(
                          label: Text(label),
                          selected: selectedStatus == label,
                          onSelected: (selected) {
                            setState(() => selectedStatus = label);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<OrderModel>>(
                stream: FirebaseFirestore.instance
                    .collection('orders1')
                    .orderBy('createdAt', descending: true)
                    .snapshots()
                    .map((snapshot) => snapshot.docs
                        .map((doc) => OrderModel.fromFirestore(doc))
                        .toList()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                  }

                  final orders = snapshot.data ?? [];

                  final filtered = orders.where((order) {
                    final id = order.id.toLowerCase();
                    final name = order.customerName.toLowerCase();
                    final phone = order.customerNumber.toLowerCase();
                    final matchesSearch = id.contains(searchQuery) ||
                        name.contains(searchQuery) ||
                        phone.contains(searchQuery);

                    final matchesStatus = selectedStatus == 'الكل' ||
                        order.statusArabic == selectedStatus;

                    return matchesSearch && matchesStatus;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('لا توجد طلبات مطابقة'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final order = filtered[i];

                      String? folderName;
                      for (final folder in bulkFolders) {
                        if (folder.orderIds.contains(order.id)) {
                          folderName = folder.name;
                          break;
                        }
                      }
                      print('Order ${order.id} folder: $folderName');

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: OrderCard(
                          orderId: order.id,

                          userName: order.customerName,
                          customerPhone: order.customerNumber,
                          createdAt: order.createdAt,
                          status: order.statusArabic,
                          pieces: order.pieceCount,
                          deposit: order.deposit,
                          totalPrice: order.totalPrice,
                          shippingType: order.shippingType,
                          paymentMethod: order.paymentMethod,
                          linkedOrderIds: order.linkedOrderIds,
                          shippingCost: order.shippingCost,
                          folderName: folderName,
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

                          emName: order.userName,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class OrderCard extends StatelessWidget {
//   final OrderModel order;
//
//   const OrderCard({Key? key, required this.order}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final statusColor = _getStatusColor(order.statusArabic);
//     final dateFormatted = DateFormat('yyyy/MM/dd – HH:mm').format(order.createdAt);
//
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 3,
//       child: ListTile(
//         onTap: () {
//           AppRouter.goToOrderDetails(context, order);
//         },
//         title: Text('طلب #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('الاسم: ${order.customerName}'),
//             Text('الهاتف: ${order.customerNumber}'),
//             Text('التاريخ: $dateFormatted'),
//
//           ],
//         ),
//         trailing: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//           decoration: BoxDecoration(
//             color: statusColor.withOpacity(0.15),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             _getStatusLabel(order.statusArabic),
//             style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Color _getStatusColor(String  status) {
//     switch (status) {
//       case 'عرابين':
//         return Colors.orange;
//       case 'حجوزات':
//         return Colors.blue;
//       case 'تم الشراء':
//         return Colors.teal;
//       case 'جاهزة':
//         return Colors.green;
//       case 'مسلمة':
//         return Colors.grey;
//       default:
//         return Colors.black;
//     }
//   }
//
//   String _getStatusLabel(String  status) {
//     switch (status) {
//       case 'عرابين':
//         return 'عربون';
//       case 'حجوزات':
//         return 'محجوز';
//       case 'تم الشراء':
//         return 'قيد التجهيز';
//       case 'جاهزة':
//         return 'تم الشراء';
//       case 'مسلمة':
//         return 'تم التسليم';
//       default:
//         return 'unKonwn';
//     }
//   }
//
//
// }
