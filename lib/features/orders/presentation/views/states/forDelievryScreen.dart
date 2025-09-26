import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/app_router/routes.dart';
import '../../../data/model/CompletedGroupModel.dart';
import '../../../data/model/orderModel.dart';
import '../../cubit/orders_cubit.dart';
import '../../cubit/orders_state.dart';

// The ForDelievryScreen widget
class ForDelievryScreen extends StatefulWidget {
  final List<String> userRoles;
  final BulkFolder? bulk;

  const ForDelievryScreen({super.key, required this.userRoles, this.bulk});

  @override
  State<ForDelievryScreen> createState() => _ForDelievryScreenState();
}

// The State for ForDelievryScreen
class _ForDelievryScreenState extends State<ForDelievryScreen> {
  Map<String?, List<OrderModel>> _groupedOrders = {};
  Map<String, BulkFolder?> _orderFolders = {};
  bool _isGroupingOrders =
      true; // New state variable to manage grouping loading
  List<String> userRoles = [];
  bool isLoadingRoles = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRoles();
    context.read<OrderCubit>().loadOrdersByStatus(OrderStatus.fordelivered);
  }

  Future<void> _fetchUserRoles() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        userRoles = [];
        isLoadingRoles = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final rolesFromDb = userDoc.data()?['role'];

      setState(() {
        if (rolesFromDb is String) {
          // If it's just a single role string
          userRoles = [rolesFromDb];
        } else if (rolesFromDb is List) {
          // If it's already a list
          userRoles = List<String>.from(rolesFromDb);
        } else {
          // If it's null or unexpected type
          userRoles = [];
        }

        isLoadingRoles = false;
      });

      debugPrint("Fetched user roles: $userRoles");
    } catch (e) {
      debugPrint("Error fetching user roles: $e");
      setState(() {
        userRoles = [];
        isLoadingRoles = false;
      });
    }
  }

  // Asynchronous function to group orders and update the state
  Future<void> _groupOrdersAndSetState(List<OrderModel> orders) async {
    // Set loading state to true for the grouping process
    if (mounted) {
      setState(() {
        _isGroupingOrders = true;
      });
    }

    Map<String?, List<OrderModel>> grouped = {};
    Map<String, BulkFolder?> folders = {};

    // Perform the asynchronous data fetching and grouping
    // This loop is the source of the initial "white screen" delay
    for (var order in orders) {
      final bulk = await _getBulkFolderForOrder(order.id);
      folders[order.id] = bulk;
      final folderId = bulk?.id;

      grouped.putIfAbsent(folderId, () => []);
      grouped[folderId]!.add(order);
    }

    // Sort each group from newest to oldest for consistent display
    grouped.forEach(
        (key, list) => list.sort((a, b) => b.createdAt.compareTo(a.createdAt)));

    // Update the state with the grouped data once the process is complete
    if (mounted) {
      setState(() {
        _groupedOrders = grouped;
        _orderFolders = folders;
        _isGroupingOrders = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          // Listen for state changes to trigger side effects
          if (state is OrderFailure) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is OrderOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          // When orders are successfully loaded, start the grouping process
          if (state is OrdersLoaded) {
            final orders = state.orders
                .where((order) =>
                    order.status == OrderStatus.fordelivered &&
                    order.shippingCost != null &&
                    order.shippingType != null)
                .toList();

            _groupOrdersAndSetState(orders);
          }
        },
        builder: (context, state) {
          // Build the UI based on the current state
          if (state is OrderLoading) {
            // Show a loader for the initial data fetch from the cubit
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrdersLoaded) {
            // Show a loader specifically for the grouping process
            if (_isGroupingOrders) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filter orders
            final orders = state.orders
                .where((order) =>
                    order.status == OrderStatus.fordelivered &&
                    order.shippingCost != null &&
                    order.shippingType != null)
                .toList();

            // Show a message if there are no orders
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delivery_dining,
                        size: 100, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      "لا توجد طلبات جاهزة للتسليم",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            // Build the ListView with the grouped orders
            return ListView(
                padding: const EdgeInsets.all(8),
                children: () {
                  final sortedEntries = _groupedOrders.entries.toList();

                  sortedEntries.sort((a, b) {
                    final nameA = a.value.isNotEmpty
                        ? _orderFolders[a.value.first.id]?.name ?? "0"
                        : "0";
                    final nameB = b.value.isNotEmpty
                        ? _orderFolders[b.value.first.id]?.name ?? "0"
                        : "0";

                    final numberA = int.tryParse(nameA.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    final numberB = int.tryParse(nameB.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

                    return numberB.compareTo(numberA);
                  });

                  return sortedEntries.map((entry) {
                    final folderId = entry.key;
                    final folderName = entry.value.isNotEmpty
                        ? _orderFolders[entry.value.first.id]?.name ?? "طرد غير محدد"
                        : "طرد غير محدد";

                    final orderCount = entry.value.length; // ✅ Get the number of orders here

                    return ExpansionTile(
                      title: Text(
                        "الطرد: $folderName ($orderCount طلبات)", // ✅ Add the order count to the title
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blueGrey,
                        ),
                      ),
                      children: entry.value.map((order) {
                        return DeliveryOrderCard(
                          order: order,
                          onDeliver: () => _confirmDelivery(context, order),
                          onReturnToProcessing: () => _returnToReserved(context, order),
                          folderName: folderName,
                          folderId: folderId,
                          userRoles: userRoles,
                        );
                      }).toList(),
                    );
                  }).toList();
                }());          }

          // Fallback loader for any other unrecognized state
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // Helper method to return an order to a previous state
  Future<void> _returnToReserved(BuildContext context, OrderModel order) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد العملية"),
        content: const Text("هل أنت متأكد أنك تريد إرجاع الطلب?؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<OrderCubit>().updateOrderStatus(
            order.id,
            OrderStatus.processing,
            force: true,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في التعديل: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelivery(BuildContext context, OrderModel order) async {
    final cubit = context.read<OrderCubit>();
    final paymentMethod = await _showPaymentMethodDialog(context);

    if (paymentMethod != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("تأكيد التسليم"),
          content: const Text("هل أنت متأكد أنك سلمت هذا الطلب؟"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("إلغاء"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("تأكيد"),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final updatedOrder = order.copyWith(
          status: OrderStatus.delivered,
          paymentMethod: paymentMethod,
        );

        await cubit.updateOrderDetails2(updatedOrder);

        // ✅ reload the fordelivery list after update
        cubit.loadOrdersByStatus(OrderStatus.fordelivered);
      }
    }
  }

  Future<String?> _showPaymentMethodDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("اختر طريقة الدفع"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'كاش'),
            child: const Text("كاش"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'بطاقة'),
            child: const Text("بطاقة"),
          ),
        ],
      ),
    );
  }
}

// Global helper function to get a bulk folder for a given order ID
Future<BulkFolder?> _getBulkFolderForOrder(String orderId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('completedGroups1')
      .where('orderIds', arrayContains: orderId)
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    return BulkFolder.fromFirestore(snapshot.docs.first);
  }
  return null;
}

class DeliveryOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onDeliver;
  final VoidCallback onReturnToProcessing;
  final String? folderName;
  final String? folderId;
  final List<String> userRoles;
  final List<String>? linkedOrderIds;


  const DeliveryOrderCard({
    super.key,
    required this.order,
    required this.onDeliver,
    required this.onReturnToProcessing,
    this.folderName,
    this.folderId, required this.userRoles, this.linkedOrderIds,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAdmin =
        userRoles.contains('admin') || userRoles.contains('manager') || userRoles.contains('coordinator');

    return GestureDetector(
      onTap: () async {
        final result = await AppRouter.goToOrderDetails2<bool>(
          context,
          order: order,
        );
        if (result == true) {
          context.read<OrderCubit>().loadOrdersByStatus(OrderStatus.pending);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row (Order ID + Status)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "#${order.id}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Chip(
                    label: Text(order.statusArabic),
                    backgroundColor: order.statusColor.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: order.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const Divider(height: 20, thickness: 1, color: Colors.black12),

              // ── Folder info + linked badge
              if (folderName != null && folderName!.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "الطرد: $folderName",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (order.linkedOrderIds != null &&
                        order.linkedOrderIds!.isNotEmpty)
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo.shade100),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.link, size: 14, color: Colors.indigo),
                            SizedBox(width: 4),
                            Text("مرتبط",
                                style:
                                TextStyle(color: Colors.indigo, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Customer Info
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text("العميل: ${order.customerName}"),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text("الهاتف: ${order.customerNumber}"),
                ],
              ),

              const SizedBox(height: 12),

              // ── Shipping Type
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 18,),
                  const SizedBox(width: 6),
                  Text(
                    order.shippingType == "free"
                        ? "الشحن: مجاني"
                        : "الشحن: مدفوع",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Price Row
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    "${order.totalPrice + (order.shippingCost ?? 0) - order.deposit} د.ل",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delivery_dining, color: Colors.black),
                      label: const Text(
                        "تم التسليم",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: onDeliver,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(Icons.undo, color: Colors.red),
                      tooltip: "إرجاع إلى قيد المعالجة",
                      onPressed: onReturnToProcessing,
                    ),
                ],
              ),
            ],
          ),
        ),
      )

    );
  }
}
