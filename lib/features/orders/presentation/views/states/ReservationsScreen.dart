import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:toastification/toastification.dart';
import '../../../../../core/app_router/routes.dart';
import '../../../../../core/constants/card_widget.dart';
import '../../../data/dataSource/order_data_source.dart';
import '../../../data/model/orderModel.dart';
import '../../cubit/OrderDetailsCubit.dart';
import '../../cubit/orders_cubit.dart';
import '../../cubit/orders_state.dart';
import '../detailsScreen2.dart';

class ReservationsScreen extends StatefulWidget {
  final List<String> userRoles;

  const ReservationsScreen({super.key, required this.userRoles});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentBulkId;
  final Set<String> _selectedOrderIds = {};
  int _nextBulkNumber = 1;
  bool _isLoading = false;
  final int _maxBulkItems = 20;
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.userRoles.contains('admin') ||
        widget.userRoles.contains('manager');

    return BlocProvider(
      create: (_) =>
          OrderCubit(OrderRemoteDataSource(FirebaseFirestore.instance))
            ..loadOrdersByStatus(OrderStatus.reserved),
      child: Scaffold(
        appBar: AppBar(
          actions: [
            if (isAdmin) ...[
              IconButton(
                icon: const Icon(Icons.create_new_folder),
                tooltip: "إضافة طرد جديد",
                onPressed: _isLoading ? null : _createNewBulkFolder,
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : BlocBuilder<OrderCubit, OrderState>(
                builder: (context, state) {
                  if (state is OrdersLoaded) {
                    final orders = state.orders;

                    if (orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 100, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                "لا توجد طلبات محجوزة حتى الآن.",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final reservedOrders = state.orders
                        .where((order) => order.status == OrderStatus.reserved)
                        .toList();

                    return Column(
                      children: [
                        if (reservedOrders.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  icon: Icon(
                                    _selectedOrderIds.length == reservedOrders.length
                                        ? Icons.remove_done
                                        : Icons.done_all,
                                  ),
                                  label: Text(
                                    _selectedOrderIds.length == reservedOrders.length
                                        ? "إلغاء التحديد"
                                        : "تحديد الكل",
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_selectedOrderIds.length == reservedOrders.length) {
                                        // Deselect all
                                        _selectedOrderIds.clear();
                                      } else {
                                        // Select all
                                        _selectedOrderIds
                                            .addAll(reservedOrders.map((order) => order.id!));
                                      }
                                    });
                                  },
                                ),
                                if (_selectedOrderIds.isNotEmpty)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text("إضافة الطلبات المحددة"),
                                    onPressed: _assignOrdersToBulk,
                                  ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: _buildOrdersList(reservedOrders),
                        ),
                      ],
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    final totalSelectedPieces = _getTotalSelectedPieces(orders);

    return Column(
      children: [
        if (_selectedOrderIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: totalSelectedPieces >= 100
                ? Colors.red.shade100
                : Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "📦 إجمالي القطع المحددة: $totalSelectedPieces",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        totalSelectedPieces >= 100 ? Colors.red : Colors.black,
                  ),
                ),
                if (totalSelectedPieces >= 100)
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final isAdmin = widget.userRoles.contains('admin') ||
                  widget.userRoles.contains('manager');

              return OrderCard(
                orderId: order.id,
                userName: order.customerName,
                customerPhone: order.customerNumber,
                createdAt: order.createdAt,
                status: order.statusArabic,
                pieces: order.pieceCount,
                deposit: order.deposit,
                totalPrice: order.totalPrice,
                linkedOrderIds: order.linkedOrderIds,
                showCheckbox: isAdmin,
                isChecked: _selectedOrderIds.contains(order.id),
                onCheckboxChanged: isAdmin
                    ? (bool? v) {
                        setState(() {
                          if (v == true) {
                            _selectedOrderIds.add(order.id!);
                          } else {
                            _selectedOrderIds.remove(order.id);
                          }
                        });
                      }
                    : null,
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
                  );
                },
                emName: order.userName,
              );
            },
          ),
        ),
      ],
    );
  }

  int _getTotalSelectedPieces(List<OrderModel> orders) {
    return orders
        .where((order) => _selectedOrderIds.contains(order.id))
        .fold(0, (sum, order) => sum + (order.pieceCount ?? 0));
  }

  Future<void> _createNewBulkFolder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد الإنشاء"),
        content: const Text("هل تريد إنشاء طرد جديد وإضافة الطلبات إليه؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Continue with creation if confirmed
    setState(() => _isLoading = true);
    try {
      final bulks = await _firestore
          .collection('completedGroups1')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (bulks.docs.isNotEmpty) {
        final lastName = bulks.docs.first['name'];
        final lastNumber =
            int.tryParse(lastName.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        _nextBulkNumber = lastNumber + 1;
      }

      final bulkName = "طرد $_nextBulkNumber";
      final docRef = _firestore.collection('completedGroups1').doc();

      await docRef.set({
        'name': bulkName,
        'orderIds': _selectedOrderIds.toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      final batch = _firestore.batch();
      for (final orderId in _selectedOrderIds) {
        final orderRef = _firestore.collection('orders1').doc(orderId);
        batch.update(orderRef, {
          'folderId': docRef.id,
          'status': 'completed',
        });
      }
      await batch.commit();

      setState(() {
        _currentBulkId = docRef.id;
        _nextBulkNumber++;
        _selectedOrderIds.clear();
      });



      toastification.show(
        type: ToastificationType.success,
        context: context,
        title: Text("✅ تم إنشاء $bulkName وتمت إضافة الطلبات إليه."),
        autoCloseDuration: Duration(seconds: 5),
      );



      context.read<OrderCubit>().loadOrdersByStatus(OrderStatus.reserved);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ فشل في إنشاء الطرد: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignOrdersToBulk() async {
    if (_selectedOrderIds.isEmpty) {

      toastification.show(
        type: ToastificationType.warning,
        context: context,
        title: Text("⚠️ لم يتم تحديد أي طلبات"),
        autoCloseDuration: Duration(seconds: 5),
      );

      return;
    }

    if (_selectedOrderIds.length > _maxBulkItems) {


      toastification.show(
        type: ToastificationType.success,
        context: context,
        title: Text("⚠️ الحد الأقصى للطلبات في الطرد هو $_maxBulkItems"),
        autoCloseDuration: Duration(seconds: 5),
      );
      return;
    }

    // ✅ اسأل المستخدم عن الطرد المطلوب
    final selectedBulkId = await _showBulkSelectionDialog();
    if (selectedBulkId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الإضافة"),
        content: Text(
            "هل تريد إضافة ${_selectedOrderIds.length} طلب إلى هذا الطرد؟"),
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

    if (confirmed != true) return;
    setState(() => _isLoading = true);

    try {
      final batch = _firestore.batch();
      final bulkRef =
          _firestore.collection('completedGroups1').doc(selectedBulkId);

      batch.update(bulkRef, {
        'orderIds': FieldValue.arrayUnion(_selectedOrderIds.toList()),
      });

      for (final orderId in _selectedOrderIds) {
        final orderRef = _firestore.collection('orders1').doc(orderId);
        batch.update(orderRef, {
          'folderId': selectedBulkId,
          'status': 'completed',
        });
      }

      await batch.commit();
      context.read<OrderCubit>().loadOrdersByStatus(OrderStatus.reserved);

      setState(() {
        _selectedOrderIds.clear();
        _currentBulkId = selectedBulkId;
      });

      toastification.show(
        type: ToastificationType.success,
        context: context,
        title: Text("✅ تمت إضافة الطلبات بنجاح"),
        autoCloseDuration: Duration(seconds: 5),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ فشل في الإضافة: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _showBulkSelectionDialog() async {
    final folders = await _firestore
        .collection('completedGroups1')
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .get();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  const Text(
                    "اختر طرد لإضافة الطلبات إليه:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (folders.docs.isEmpty)
                    const Text("لا توجد طرود قيد المعالجة حالياً."),
                  ...folders.docs.map((doc) {
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(doc['name']),
                      onTap: () {
                        Navigator.pop(context, doc.id);
                      },
                    );
                  }).toList(),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.create_new_folder, color: Colors.orange),
                    title: const Text("إنشاء طرد جديد"),
                    onTap: () async {
                      Navigator.pop(context);
                      await _createNewBulkFolder();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

  }
}
