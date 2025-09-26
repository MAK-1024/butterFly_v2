


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui' as ui;
import '../../../../../core/constants/card_widget.dart';
import '../../../data/model/CompletedGroupModel.dart';
import '../../../data/model/orderModel.dart';
import '../../cubit/OrderDetailsCubit.dart';
import '../../cubit/bulk_cubit.dart';
import '../../cubit/bulk_state.dart';
import '../detailsScreen2.dart';

class DeliveredScreen extends StatefulWidget {
  final List<String> userRoles;

  const DeliveredScreen({super.key, required this.userRoles});

  @override
  State<DeliveredScreen> createState() => _DeliveredScreenState();
}

class _DeliveredScreenState extends State<DeliveredScreen> {
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
    final completedBulks = bulks.where((b) => b.status == 'Delivered').toList();

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
                icon: const Icon(Icons.arrow_back, color: Colors.blue),
                onPressed: () async {
                  final ok =
                  await _confirm(context, 'تغيير حالة الطرد والطلبات؟');
                  if (ok ?? false) {
                    context.read<BulkCubit>().markBulkProcessing(g);
                  }
                },
              ),


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
    final shipCtrl = TextEditingController(text: g.shippingCost?.toString());
    final costCtrl = TextEditingController(text: g.totalCost?.toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل بيانات الطرد'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field("اسم السلة (اختياري)", nameCtrl),
              _field("اسم السلة", nameCtrl2),
              _field("رقم التتبع", trackCtrl),
              _field("ملاحظة", noteCtrl, maxLines: 3),
              _field("قيمة الشحن", shipCtrl, type: TextInputType.number),
              _field("تكلفة الطرد", costCtrl, type: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              context.read<BulkCubit>().updateBulk(g.id, {
                'name': nameCtrl.text.trim().isEmpty
                    ? g.name
                    : nameCtrl.text.trim(),
                'name2': nameCtrl2.text.trim(),
                'trackNumber': trackCtrl.text.trim(),
                'note': noteCtrl.text.trim(),
                'shippingCost':
                double.tryParse(shipCtrl.text) ?? g.shippingCost,
                'totalCost': double.tryParse(costCtrl.text) ?? g.totalCost,
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

  const BulkOrdersScreen(
      {super.key, required this.bulk, required this.userRoles});

  @override
  State<BulkOrdersScreen> createState() => _BulkOrdersScreenState();
}

class _BulkOrdersScreenState extends State<BulkOrdersScreen> {
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
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text("الطلبات في ${widget.bulk.name}")),
        body: FutureBuilder<List<OrderModel>>(
            future: _fetchOrdersByIds(widget.bulk.orderIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());

              if (snapshot.hasError)
                return Center(child: Text('حدث خطأ: ${snapshot.error}'));

              final orders = snapshot.data!;
              if (orders.isEmpty)
                return const Center(child: Text('لا توجد طلبات في هذا الطرد'));

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: orders.length,
                itemBuilder: (_, i) {
                  final order = orders[i];
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
                      statusColor: order.statusColor,
                      shippingType: order.shippingType,
                      paymentMethod: order.paymentMethod,
                      folderName: widget.bulk.name,
                      linkedOrderIds: order.linkedOrderIds,
                      shippingCost: order.shippingCost,
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider<OrderDetailsCubit>(
                              create: (_) => OrderDetailsCubit(),
                              child: OrderDetailsScreen2(
                                order: order, userRoles: [],
                              ),
                            ),
                          ),
                        );
                      },
                      emName: order.userName,
                    ),
                  );
                },
              );
            }),
      ),
    );
  }

  double getAdjustedTotalPrice({
    required double basePrice,
    required String? shippingType,
  }) {
    if (shippingType == 'paid') {
      return basePrice + 10;
    } else if (shippingType == 'free') {
      return basePrice - 10;
    } else {
      return basePrice;
    }
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
