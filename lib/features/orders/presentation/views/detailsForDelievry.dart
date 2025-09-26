import 'package:butterfly_v2/features/orders/presentation/views/screen_shot.dart';
import 'package:butterfly_v2/features/orders/presentation/views/updateScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/model/CartLinkModel.dart';
import '../../data/model/orderModel.dart';
import '../cubit/orders_cubit.dart';

class DetailsForDelievry extends StatefulWidget {
  final OrderModel order;

  const DetailsForDelievry({super.key, required this.order});

  @override
  State<DetailsForDelievry> createState() => _DetailsForDelievryState();
}

class _DetailsForDelievryState extends State<DetailsForDelievry> {
  OrderStatus _currentStatus = OrderStatus.pending;
  final _dateFormat = DateFormat('yyyy/MM/dd - HH:mm');
  final _currencyFormat = NumberFormat.currency(symbol: 'د.ل');
  bool _deliveryInfoSaved = false;
  bool _isLoading = true;
  OrderModel? _order;
  bool _showDeliveryAndShippingStage = true;
  bool _deliveryConfirmed = false;
  bool _isShippingConfirmed = false;
  bool isLoadingRoles = true;

  String? _paymentMethod;
  DeliveryType? _deliveryType;
  TextEditingController _shippingCostController = TextEditingController();

  String get _shippingTypeString =>
      _deliveryType == DeliveryType.paid ? 'مدفوع' : 'مجاني';

  late List<CartLink> _editableLinks;

  @override
  void initState() {
    super.initState();
    _listenToOrder();
    context.read<OrderCubit>().listenToOrder(widget.order.id);
    _editableLinks =
        widget.order.cartLinks.map((link) => link.copyWith()).toList();

    _shippingCostController = TextEditingController(
      text:
          (widget.order.shippingCost != null && widget.order.shippingCost! > 0)
              ? widget.order.shippingCost!.toStringAsFixed(2)
              : '',
    );

    if (widget.order.shippingCost != null &&
        widget.order.shippingCost! > 0 &&
        widget.order.shippingType != null &&
        widget.order.shippingType!.isNotEmpty) {
      _isShippingConfirmed = true;
      _showDeliveryAndShippingStage = false;
    } else {
      _isShippingConfirmed = false;
      _showDeliveryAndShippingStage = true;
    }
  }

  @override
  void dispose() {
    _shippingCostController.dispose();
    super.dispose();
  }

  void _listenToOrder() {
    setState(() => _isLoading = true);

    FirebaseFirestore.instance
        .collection('orders1')
        .doc(widget.order.id)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final updatedOrder = OrderModel.fromFirestore(doc);
        setState(() {
          _order = updatedOrder;
          _currentStatus = _order!.status;

          // update local editable links when Firestore updates
          _editableLinks =
              updatedOrder.cartLinks.map((link) => link.copyWith()).toList();

          _isLoading = false;
        });
      } else {
        setState(() {
          _order = null;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        '${widget.order.id}#',
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        IconButton(
            icon: Icon(Icons.print, size: 24.sp), onPressed: _printInvoice),
        _buildPopupMenu(),
      ],
    );
  }

  Widget _buildBody() {
    final currentOrder = _order ?? widget.order;
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              await context.read<OrderCubit>().orders;
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildStatusChip(currentOrder),
                  SizedBox(height: 16.h),
                  _buildOrderSummaryCard(currentOrder),
                  SizedBox(height: 16.h),
                  _buildProductsCard(currentOrder),
                  if (widget.order.linkedOrderIds?.isNotEmpty ?? false) ...[
                    SizedBox(height: 16.h),
                    _buildLinkedOrdersCard(currentOrder),
                  ],
                ],
              ),
            ),
          );
  }

  PopupMenuButton<String> _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 24.sp),
      onSelected: (value) => _handlePopupAction(value, context),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'copy',
          child: ListTile(
            leading: Icon(Icons.content_copy, size: 20.sp),
            title: Text('نسخ معلومات الطلب', style: TextStyle(fontSize: 14.sp)),
          ),
        ),
        if (_currentStatus == OrderStatus.pending ||
            _currentStatus == OrderStatus.reserved ||
            _currentStatus == OrderStatus.completed ||
            _currentStatus == OrderStatus.processing ||
            _currentStatus == OrderStatus.fordelivered)
          PopupMenuItem(
            value: 'link',
            child: ListTile(
              leading: Icon(Icons.link, size: 20.sp),
              title: Text('ربط الطلب', style: TextStyle(fontSize: 14.sp)),
            ),
          ),
      ],
    );
  }

  void _handlePopupAction(String action, BuildContext context) async {
    switch (action) {
      case 'copy':
        _copyOrderInfo();
        break;
      case 'edit':
        final updatedOrder = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EditOrderScreen(order: widget.order)),
        );

        break;

      case 'link':
        _showLinkOrdersDialog();
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  void _copyOrderInfo() {
    context.read<OrderCubit>().copyOrderInfo(widget.order);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ معلومات الطلب')),
    );
  }

  void _printInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceScreen(order: widget.order),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    return Column(
      children: [
        if (_currentStatus == OrderStatus.pending)
          _buildStatusActionButton(
            icon: Icons.lock_clock_rounded,
            label: "تحويل إلى محجوز",
            color: Colors.orange,
            onPressed: () => _changeStatus(OrderStatus.reserved),
          ),
        if (_currentStatus == OrderStatus.processing)
          _buildDeliveryAndPaymentSection(),
      ],
    );
  }

  Widget _buildOrderSummaryCard(OrderModel order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildSummaryRow(
                "تاريخ الطلب", _dateFormat.format(order.createdAt)),
            _buildSummaryRow("الموظف", order.userName),
            _buildSummaryRow("الزبون", order.customerName),
            _buildSummaryRow("رقم الهاتف", order.customerNumber, isPhone: true),
            if (order.address.isNotEmpty)
              _buildSummaryRow("العنوان", order.address),
            Divider(height: 24.h),
            _buildSummaryRow(
                "الإجمالي", _currencyFormat.format(order.totalPrice),
                isAmount: true),
            _buildSummaryRow(
                "الشحن", _currencyFormat.format(order.shippingCost),
                isAmount: true),
            if (order.deposit > 0)
              _buildSummaryRow("العربون", _currencyFormat.format(order.deposit),
                  isAmount: true),
            if ((order.totalPrice - order.deposit) > 0)
              _buildSummaryRow(
                  "المتبقي",
                  _currencyFormat.format(order.totalPrice -
                      order.deposit +
                      order.shippingCost!.toDouble()),
                  isAmount: true),

            SizedBox(height: 12.h),

            // ...widget.order.cartLinks
            //     .map((link) => _buildProductItem(link))
            //     .toList(),

            SizedBox(height: 12.h),
            Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "إجمالي القطع: ${_calculateTotalPieces()}",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAndPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showDeliveryAndShippingStage && !_isShippingConfirmed) ...[
          _buildExpansionCard(
            title: 'تكلفة الشحن',
            initiallyExpanded: true,
            content: _buildShippingCostField(),
          ),
          _buildExpansionCard(
            title: 'خيارات التوصيل',
            content: _buildDeliveryOptionsSection(),
          ),
          SizedBox(height: 16.h),
          _buildConfirmButton(),
        ] else ...[
          _buildExpansionCard(
            title: 'طريقة الدفع',
            content: _buildPaymentMethodSection(),
            initiallyExpanded: true,
          ),
          SizedBox(height: 16.h),
          _buildDeliverButton(),
        ],
      ],
    );
  }

  Future<void> _updatePaymentMethod() async {
    try {
      await FirebaseFirestore.instance
          .collection('orders1')
          .doc(widget.order.id)
          .update({
        'paymentMethod': _paymentMethod,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحديث طريقة الدفع: ${e.toString()}')),
      );
      rethrow;
    }
  }

  Widget _buildDeliverButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_paymentMethod == null || _paymentMethod!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("يرجى اختيار طريقة الدفع")),
          );
          return;
        }

        try {
          await _changeStatus(OrderStatus.delivered);

          await _updatePaymentMethod();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم تسليم الطلب بنجاح")),
          );
          // if (mounted) Navigator.pop(context);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل في عملية التسليم: ${e.toString()}')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text(
        "تسليم الطلب",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusChip(OrderModel order) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: _statusColor(order.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _statusColor(order.status),
          width: 1,
        ),
      ),
      child: Text(
        order.statusArabic,
        style: TextStyle(
          color: _statusColor(order.status),
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isPhone = false, bool isAmount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          Spacer(),
          if (isPhone)
            InkWell(
              onTap: () => _launchPhone(value),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            )
          else if (isAmount)
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsCard(currentOrder) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  int _calculateTotalPieces() {
    return _editableLinks.fold(0, (sum, link) => sum + link.pieces);
  }

  Widget _buildStatusActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20.sp, color: color),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionCard({
    required String title,
    required Widget content,
    bool initiallyExpanded = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: () async {
        final shippingCost = double.tryParse(_shippingCostController.text);
        final deliveryType = _deliveryType;

        if (shippingCost == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('يرجى إدخال تكلفة التوصيل')),
          );
          return;
        }

        if (deliveryType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('يرجى اختيار نوع التوصيل')),
          );
          return;
        }

        try {
          await FirebaseFirestore.instance
              .collection('orders1')
              .doc(widget.order.id)
              .update({
            'shippingCost': shippingCost,
            'shippingType': deliveryType.name,
          });

          setState(() {
            _isShippingConfirmed = true;
            _showDeliveryAndShippingStage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم حفظ التوصيل بنجاح')),
          );
          Navigator.pop(context);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل في الحفظ: $e')),
          );
        }
      },
      child: Text('تأكيد'),
    );
  }

  Widget _buildDeliveryOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "خيارات التوصيل",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DeliveryType>(
              value: _deliveryType,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down),
              style: TextStyle(fontSize: 14.sp, color: Colors.black),
              onChanged: (value) {
                if (value != null) setState(() => _deliveryType = value);
              },
              items: DeliveryType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "طريقة الدفع",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _paymentMethod,
            onChanged: (value) {
              setState(() {
                _paymentMethod = value!;
              });
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down),
            dropdownColor: Colors.white,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black,
            ),
            items: ['كاش', 'بطاقة'].map((method) {
              return DropdownMenuItem<String>(
                value: method,
                child: Text(method),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildShippingCostField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "تكلفة التوصيل",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _shippingCostController,
          decoration: InputDecoration(
            hintText: 'أدخل تكلفة التوصيل',
            prefixIcon: Icon(Icons.local_shipping, size: 20.sp),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
          keyboardType: TextInputType.number,
          style: TextStyle(fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildLinkedOrdersCard(OrderModel order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            "الطلبات المرتبطة",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          childrenPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          collapsedIconColor: Colors.black,
          iconColor: Colors.black,
          children: [
            FutureBuilder<List<OrderModel>>(
              future: _fetchLinkedOrders(order.linkedOrderIds ?? []),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Text(
                    "لا توجد طلبات مرتبطة",
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  );
                }

                return Column(
                  children: orders
                      .map((order) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: _buildLinkedOrderItem(order),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedOrderItem(OrderModel order) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailsForDelievry(order: order),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "طلب #${order.id}",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text("العميل: ${order.customerName}",
                style: TextStyle(fontSize: 13.sp)),
            Text("الحالة: ${order.statusArabic}",
                style: TextStyle(
                  fontSize: 13.sp,
                  color: _statusColor(order.status),
                )),
            Text("الإجمالي: ${_currencyFormat.format(order.totalPrice)}",
                style: TextStyle(fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }

  // void _handlePopupAction(String action, BuildContext context)async {
  //   switch (action) {
  //     case 'copy':
  //       _copyOrderInfo();
  //       break;
  //     case 'edit':
  //       final updatedOrder = await Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (_) => EditOrderScreen(order: widget.order)),
  //       );
  //
  //       if (updatedOrder != null) {
  //         // Replace the old order with the updated one in state
  //         context.read<OrderCubit>().updateOrderDetails2(updatedOrder);
  //       }
  //       break;
  //
  //     case 'link':
  //       _showLinkOrdersDialog();
  //       break;
  //     case 'delete':
  //       _confirmDelete();
  //       break;
  //   }
  // }
  //

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  Future<void> _launchPhone(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تعذر فتح الاتصال")),
      );
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade700;
      case OrderStatus.reserved:
        return Colors.blue.shade700;
      case OrderStatus.processing:
        return Colors.green.shade700;
      case OrderStatus.delivered:
        return Colors.teal.shade700;
      case OrderStatus.completed:
        return Colors.grey.shade700;
      case OrderStatus.fordelivered:
        return Colors.deepOrange;
      default:
        return Colors.black87;
    }
  }

  Future<void> _changeStatus(OrderStatus newStatus) async {
    if (_currentStatus == newStatus) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد التغيير'),
        content:
            Text('هل تريد نقل الطلب إلى حالة «${_statusArabic(newStatus)}»؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await context.read<OrderCubit>().updateOrderStatus(
            widget.order.id,
            newStatus,
          );

      if (!mounted) return;
      setState(() {
        _currentStatus = newStatus;
        _isLoading = false;
      });
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الحالة بنجاح')),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحديث: $e')),
      );
    }
  }

  void _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: const Text("هل أنت متأكد من حذف هذا الطلب؟"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("إلغاء"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("حذف", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await context.read<OrderCubit>().deleteOrder(widget.order.id);

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الطلب بنجاح')),
        );

        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في حذف الطلب: $e')),
        );
      }
    }
  }

  String _statusArabic(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'عرابين';
      case OrderStatus.reserved:
        return 'حجوزات';
      case OrderStatus.processing:
        return 'جاهزة للتسليم';
      case OrderStatus.delivered:
        return 'مسلمة';
      case OrderStatus.completed:
        return 'تم الشراء';
      case OrderStatus.fordelivered:
        return 'التوصيل';
    }
  }

  Future<List<OrderModel>> _fetchLinkedOrders(List<String> ids) async {
    if (ids.length > 10) {
      List<List<String>> chunks = [];
      for (var i = 0; i < ids.length; i += 10) {
        chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
      }
      List<OrderModel> results = [];
      for (var chunk in chunks) {
        final qs = await FirebaseFirestore.instance
            .collection('orders1')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        results.addAll(qs.docs.map(OrderModel.fromFirestore));
      }
      return results;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('orders1')
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    return snapshot.docs.map(OrderModel.fromFirestore).toList();
  }

  Future<void> _showLinkOrdersDialog() async {
    final allowed = ['pending', 'reserved', 'processing', 'completed'];
    String search = '';

    // Start with current linked orders
    final List<String> selected =
        List<String>.from(widget.order.linkedOrderIds ?? []);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) {
          return AlertDialog(
            title: const Text('ربط / إلغاء ربط طلبات أخرى'),
            content: SizedBox(
              width: double.maxFinite,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'بحث بالرقم أو الاسم',
                    ),
                    onChanged: (v) => setDialogState(() => search = v.trim()),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('orders1')
                          .where('status', whereIn: allowed)
                          .snapshots(),
                      builder: (_, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final orders = snap.data!.docs
                            .map(OrderModel.fromFirestore)
                            .where((o) =>
                                (o.id.contains(search) ||
                                    o.customerName.contains(search)) &&
                                o.id != widget.order.id)
                            .toList();

                        if (orders.isEmpty) {
                          return const Center(child: Text('لا توجد نتائج'));
                        }

                        return ListView.builder(
                          itemCount: orders.length,
                          itemBuilder: (_, i) {
                            final o = orders[i];
                            final sel = selected.contains(o.id);

                            return CheckboxListTile(
                              title: Text('طلب #${o.id} - ${o.customerName}'),
                              value: sel,
                              onChanged: (v) {
                                setDialogState(() {
                                  v!
                                      ? selected.add(o.id)
                                      : selected.remove(o.id);
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, selected),
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    ).then((pickedIds) async {
      if (pickedIds == null) return;

      setState(() => _isLoading = true);

      // Update the entire linked list (adds + removes)
      await FirebaseFirestore.instance
          .collection('orders1')
          .doc(widget.order.id)
          .update({'linkedOrderIds': pickedIds});

      final updatedSnap = await FirebaseFirestore.instance
          .collection('orders1')
          .doc(widget.order.id)
          .get();
      final updatedOrder = OrderModel.fromFirestore(updatedSnap);

      if (!mounted) return;
      setState(() {
        widget.order.linkedOrderIds = updatedOrder.linkedOrderIds;
        _isLoading = false;
      });
    });
  }
}

enum DeliveryType { free, paid, none }

extension DeliveryTypeExtension on DeliveryType {
  String get label {
    switch (this) {
      case DeliveryType.free:
        return 'مجاني';
      case DeliveryType.paid:
        return 'مدفوع';
      case DeliveryType.none:
        return 'لم يتم التحديد';
    }
  }
}
