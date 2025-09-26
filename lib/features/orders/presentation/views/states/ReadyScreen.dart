
import 'dart:developer';

import 'package:butterfly_v2/core/app_router/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../../../../core/constants/card_widget.dart';
import '../../../data/model/CompletedGroupModel.dart';
import '../../../data/model/orderModel.dart';
import '../../cubit/OrderDetailsCubit.dart';
import '../../cubit/bulk_cubit.dart';
import '../../cubit/bulk_state.dart';
import '../../cubit/orders_cubit.dart';
import '../detailsScreen2.dart';

class ReadyScreen extends StatefulWidget {
  final List<String> userRoles;

  const ReadyScreen({super.key, required this.userRoles});

  @override
  State<ReadyScreen> createState() => _ReadyScreenState();
}

class _ReadyScreenState extends State<ReadyScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BulkCubit>().loadBulks();
  }

  Future<bool?> _confirm(BuildContext ctx, String msg) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('موافق')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<BulkCubit, BulkState>(
        builder: (_, state) {
          if (state is BulkLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is BulkError) return Center(child: Text(state.message));
          if (state is BulkLoaded) return _list(state.bulks);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _list(List<BulkFolder> bulks) {
    final completedBulks =
        bulks.where((b) => b.status == 'processing').toList();

    return RefreshIndicator(
      onRefresh: () async => context.read<BulkCubit>().loadBulks(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        itemCount: completedBulks.length,
        itemBuilder: (_, i) => _card(completedBulks[i]),
      ),
    );
  }

  //──────────────────────── Card
  Widget _card(BulkFolder g) {
    final isAdmin = widget.userRoles.contains('admin') ||
        widget.userRoles.contains('manager');

    final isAdmin2 = widget.userRoles.contains('admin') ||
        widget.userRoles.contains('manager');

    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(g.name,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 6.h),
            Row(
              children: [
                Text('اسم السلة :',
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.bold)),
                Text(g.name2.toString(),
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 6.h),
            _row("رقم التتبع", g.trackNumber ?? '-'),
            if (isAdmin) ...[
              _row("الملاحظات", g.note?.isEmpty ?? true ? '-' : g.note!),
              _row(
                  "قيمة الشحن",
                  g.shippingCost != null
                      ? "${g.shippingCost!.toStringAsFixed(2)} د.ل"
                      : '-'),
              _row("تكلفة الطرد", "${g.totalCost2!.toStringAsFixed(2)} \$ "),
              _row("عدد الطلبات", g.orderIds.length.toString()),
              _row("إجمالي القطع", g.calculatedPieces.toString()),
              _row("إجمالي السعر",
                  "${g.calculatedTotal.toStringAsFixed(2)} د.ل"),
            ],
            SizedBox(height: 6.h),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              //
              // Text(DateFormat('yyyy/MM/dd HH:mm').format(g.createdAt),
              //     style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
              //

              IconButton(
                icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BulkOrdersScreen(
                        bulk: g,
                        userRoles: [],
                      ),
                    ),
                  );
                },
              ),
              if (isAdmin2) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.blue),
                  tooltip: 'تحويل حالة الطرد والطلبات إلى جاهزة للتسليم',
                  onPressed: () async {
                    final ok =
                        await _confirm(context, 'تغيير حالة الطرد والطلبات؟');
                    if (ok ?? false) {
                      context.read<BulkCubit>().markBulkCompleted(g);
                    }
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.warehouse, color: Colors.orange),
                  tooltip: 'تحويل حالة الطرد والطلبات إلى جاهزة للتسليم',
                  onPressed: () async {
                    final ok =
                        await _confirm(context, 'تغيير حالة الطرد والطلبات؟');
                    if (ok ?? false) {
                      context.read<BulkCubit>().markBulkDelivered(g);
                    }
                  },
                ),
                // ✏️ Edit folder info
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green),
                  onPressed: () => _showEditDialog(g),
                ),
                // 🗑️ Delete (folder & its orders)
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () async {
                    final ok =
                        await _confirm(context, 'حذف ${g.name} وجميع طلباته؟');
                    if (ok ?? false) {
                      context.read<BulkCubit>().deleteBulk(g);
                    }
                  },
                ),
              ],
            ])
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Text("$l : $v",
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[800])),
      );

  Future<void> _showEditDialog(BulkFolder g) async {
    final nameCtrl = TextEditingController(text: g.name);
    final nameCtrl2 = TextEditingController(text: g.name2);
    final trackCtrl = TextEditingController(text: g.trackNumber);
    final noteCtrl = TextEditingController(text: g.note);
    final piecesCtrl = TextEditingController(text: g.totalPieces?.toString());
    final costCtrl = TextEditingController(text: g.totalCost?.toString());

    // Start empty
    final shipCtrl = TextEditingController(text: '');
    final costCtrl2 = TextEditingController(text: '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل بيانات الطرد'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field("اسم السلة", nameCtrl),
              _field("اسم السلة", nameCtrl2),
              _field("رقم التتبع", trackCtrl),
              _field("قيمة الشحن", shipCtrl, type: TextInputType.number),
              _field("تكلفة الطرد", costCtrl2, type: TextInputType.number),
              _field("ملاحظة", noteCtrl, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<BulkCubit>().updateBulk(g.id, {
                'name': nameCtrl.text.trim(),
                'name2': nameCtrl2.text.trim(),
                'trackNumber': trackCtrl.text.trim(),
                'note': noteCtrl.text.trim(),
                'totalPieces': int.tryParse(piecesCtrl.text) ?? g.totalPieces,
                'totalCost': costCtrl.text.isEmpty
                    ? null
                    : double.tryParse(costCtrl.text),
                'totalCost2': costCtrl2.text.isEmpty
                    ? null
                    : double.tryParse(costCtrl2.text),
                'shippingCost': shipCtrl.text.isEmpty
                    ? null
                    : double.tryParse(shipCtrl.text),
              });
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget _field(String lbl, TextEditingController c,
          {int maxLines = 1, TextInputType type = TextInputType.text}) =>
      Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: TextField(
          controller: c,
          keyboardType: type,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: lbl,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}


class BulkOrdersScreen extends StatefulWidget {
  final BulkFolder bulk;
  final List<String> userRoles;

  const BulkOrdersScreen({
    super.key,
    required this.bulk,
    required this.userRoles,
  });

  @override
  State<BulkOrdersScreen> createState() => _BulkOrdersScreenState();
}

class _BulkOrdersScreenState extends State<BulkOrdersScreen> {
  String uu = 'موظف';
  Set<String> _selectedOrders = {};
  bool _isBulkLoading = false;
  List<OrderModel> _orders = [];
  bool _loadingOrders = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadOrders();
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

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    final orders = await _fetchOrdersByIds(widget.bulk.orderIds);
    setState(() {
      _orders = orders;
      _loadingOrders = false;
    });
  }

// file: ReadyScreen.dart (inside _BulkOrdersScreenState)

  Future<void> _moveSelectedOrdersToForDelivery(BuildContext context) async {
    setState(() => _isBulkLoading = true);
    final firestore = FirebaseFirestore.instance;

    try {
      // ✅ Use a Firestore batch to update all documents efficiently
      final batch = firestore.batch();

      for (final orderId in _selectedOrders) {
        final docRef = firestore.collection('orders1').doc(orderId);

        batch.update(docRef, {
          'status': OrderStatus.fordelivered.name,
        });
      }

      await batch.commit();

      setState(() {
        _selectedOrders.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم نقل الطلبات المحددة للتوصيل بنجاح")),
      );

      // ✅ Refresh orders to show the updated status
      await _loadOrders();

    } catch (e) {
      log("فشل: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل في تحديث حالة الطلبات: $e")),
      );
    } finally {
      setState(() => _isBulkLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        floatingActionButton: _selectedOrders.isNotEmpty
            ? FloatingActionButton.extended(
          onPressed: _isBulkLoading
              ? null
              : () => _moveSelectedOrdersToForDelivery(context),
          icon: const Icon(Icons.move_down),
          label: _isBulkLoading
              ? const Text("جاري التنفيذ...")
              : Text("نقل ${_selectedOrders.length} طلب للتوصيل"),
        )
            : null,
        appBar: AppBar(title: Text("الطلبات في ${widget.bulk.name}")),
        body: _loadingOrders
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
            ? const Center(child: Text('لا توجد طلبات في هذا الطرد'))
            : RefreshIndicator(
          onRefresh: _loadOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _orders.length,
            itemBuilder: (_, i) {
              final order = _orders[i];

              final showCheckbox =
                  order.status == OrderStatus.processing &&
                      order.shippingType != null &&
                      order.shippingCost != null;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: OrderCard(
                  orderId: order.id,
                  userName: order.customerName,
                  emName: order.userName,
                  customerPhone: order.customerNumber,
                  createdAt: order.createdAt,
                  status: order.statusArabic,
                  pieces: order.pieceCount,
                  deposit: order.deposit,
                  totalPrice: order.totalPrice,
                  statusColor: order.statusColor,
                  shippingType: order.shippingType,
                  paymentMethod: order.paymentMethod,
                  linkedOrderIds: order.linkedOrderIds,
                  shippingCost: order.shippingCost,
                  folderId: widget.bulk.id,
                  folderName: widget.bulk.name,
                  onTap: () async {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider<OrderDetailsCubit>(
                          create: (_) => OrderDetailsCubit(),
                          child: OrderDetailsScreen2(
                            order: order,
                            userRoles:[],
                          ),
                        ),
                      ),
                    );
                  },

                  showCheckbox: showCheckbox,
                  isChecked: _selectedOrders.contains(order.id),
                  onCheckboxChanged: (checked) {
                    if (!showCheckbox) return;
                    setState(() {
                      if (checked == true) {
                        _selectedOrders.add(order.id);
                      } else {
                        _selectedOrders.remove(order.id);
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<List<OrderModel>> _fetchOrdersByIds(List<String> ids) async {
    final firestore = FirebaseFirestore.instance;
    final futures = ids.map((id) async {
      final doc = await firestore.collection('orders1').doc(id).get();
      if (doc.exists) return OrderModel.fromFirestore(doc);
      return null;
    });

    final results = await Future.wait(futures);
    return results.whereType<OrderModel>().toList();
  }
}
