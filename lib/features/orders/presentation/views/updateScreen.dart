import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Make sure you have this imported
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/model/orderModel.dart';
import '../../data/model/CartLinkModel.dart';

class EditOrderScreen extends StatefulWidget {
  final OrderModel order;

  const EditOrderScreen({super.key, required this.order});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  List<String> userRoles = [];
  bool isLoadingRoles = true;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _note2Controller;
  late TextEditingController _priceController;
  late TextEditingController _depositController;
  late TextEditingController _shippingCostController;
  late TextEditingController _noteController;
  late TextEditingController _piecesController;
  OrderStatus _currentStatus = OrderStatus.pending;

  String? _paymentMethod;
  String? _shippingType;
  OrderStatus? _status;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _showProducts = false;
  late List<CartLink> _editableLinks;

  @override
  void initState() {
    super.initState();
    _fetchUserRoles();

    // Initialize controllers
    _nameController = TextEditingController(text: widget.order.customerName);
    _phoneController = TextEditingController(text: widget.order.customerNumber);
    _priceController = TextEditingController(
      text: widget.order.totalPrice.toStringAsFixed(2),
    );
    _piecesController = TextEditingController(
      text: widget.order.pieceCount.toString(),
    );
    _addressController = TextEditingController(text: widget.order.address);
    _note2Controller = TextEditingController(text: widget.order.note2);

    _depositController = TextEditingController(
      text: widget.order.deposit.toStringAsFixed(2),
    );
    _shippingCostController = TextEditingController(
      text: widget.order.shippingCost?.toStringAsFixed(2) ?? '',
    );
    _noteController = TextEditingController(text: widget.order.note);

    // Ensure dropdown values match exactly with items
    _paymentMethod = null;
    _shippingType = null;
    _status = widget.order.status;

    _editableLinks = widget.order.cartLinks
        .map((link) => CartLink(
      link: link.link,
      pieces: link.pieces,
      note: link.note,
    ))
        .toList();
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

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _piecesController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _depositController.dispose();
    _shippingCostController.dispose();
    _noteController.dispose();
    _note2Controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingRoles) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    print('Fetched user roles: $userRoles');

    final bool isCoordinator = userRoles.contains('coordinator') || userRoles.contains('delivery');
    final bool isAdmin =  userRoles.contains('admin') || userRoles.contains('manager') || userRoles.contains('user');
    final bool isPros = widget.order.status == OrderStatus.processing;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تعديل الطلب #${widget.order.id}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveChanges,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                if (isCoordinator && isPros) ...[
                  // Show only payment and shipping for coordinators
                  _buildPaymentShippingSection(),
                  SizedBox(height: 30.h),
                  _buildSaveButton(),
                ] else if (isAdmin) ...[
                  // Show full form for admin/manager
                  _buildCustomerInfoSection(),
                  SizedBox(height: 20.h),
                  _buildOrderDetailsSection(),
                  SizedBox(height: 20.h),
                  _buildProductsSection(),
                  SizedBox(height: 20.h),
                  if (isPros) _buildPaymentShippingSection(),
                  SizedBox(height: 30.h),
                  _buildSaveButton(),
                ] else ...[
                  Center(
                    child: Text(
                      'ليس لديك صلاحيات تعديل الطلب',
                      style: TextStyle(fontSize: 18.sp, color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    // Your existing code here
    // ...
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _formField(
              controller: _nameController,
              label: 'اسم العميل',
              icon: Icons.person,
              validator: (value) =>
              value?.isEmpty ?? true ? 'هذا الحقل مطلوب' : null,
            ),
            SizedBox(height: 12.h),
            _formField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              icon: Icons.phone,
              keyboard: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'هذا الحقل مطلوب';
                if (!RegExp(r'^[0-9]+$').hasMatch(value!)) {
                  return 'يجب أن يحتوي على أرقام فقط';
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _formField(
              controller: _addressController,
              label: 'العنوان',
              icon: Icons.location_on,
              maxLines: 2,
            ),
            SizedBox(height: 12.h),
            _formField(
              controller: _note2Controller,
              label: 'ملاحظة',
              icon: Icons.note,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsSection() {
    // Your existing code here
    // ...
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _formField(
              controller: _priceController,
              label: 'الاجمالي',
              icon: Icons.attach_money,
              keyboard: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'هذا الحقل مطلوب';
                if (double.tryParse(value!) == null) return 'قيمة غير صالحة';
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _formField(
              controller: _depositController,
              label: 'العربون',
              icon: Icons.attach_money,
              keyboard: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return null;
                if (double.tryParse(value!) == null) return 'قيمة غير صالحة';
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _formField(
              controller: _piecesController,
              label: 'عدد القطع',
              icon: Icons.grid_view,
              keyboard: TextInputType.number,
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المنتجات (${_editableLinks.length})',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                          _showProducts ? Icons.expand_less : Icons.expand_more),
                      onPressed: () =>
                          setState(() => _showProducts = !_showProducts),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.green),
                      tooltip: "إضافة منتج جديد",
                      onPressed: () => _addNewProduct(),
                    ),
                  ],
                ),
              ],
            ),
            if (_showProducts) ...[
              Divider(),
              ..._editableLinks.map((link) => _buildProductItem(link)).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentShippingSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildDropdown(
              value: _paymentMethod,
              items: const ['كاش', 'بطاقة' ],
              label: 'طريقة الدفع',
              icon: Icons.payment,
              onChanged: (value) => setState(() => _paymentMethod = value),
              validator: (value) => value == null ? 'هذا الحقل مطلوب' : null,
            ),
            SizedBox(height: 12.h),
            _buildDropdown(
              value: _shippingType,
              items: const ['مجاني', 'مدفوع', 'استلام شخصي'],
              label: 'نوع الشحن',
              icon: Icons.delivery_dining,
              onChanged: (value) => setState(() => _shippingType = value),
              validator: (value) => value == null ? 'هذا الحقل مطلوب' : null,
            ),
            SizedBox(height: 12.h),
            _formField(
              controller: _shippingCostController,
              label: 'تكلفة الشحن',
              icon: Icons.local_shipping,
              keyboard: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return null;
                if (double.tryParse(value!) == null) return 'قيمة غير صالحة';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProductItem(CartLink link) {
    final index = _editableLinks.indexOf(link);
    final linkController = TextEditingController(text: link.link);
    final piecesController = TextEditingController(text: link.pieces.toString());
    final noteController = TextEditingController(text: link.note ?? '');

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined,
                  size: 20.sp, color: Colors.grey.shade600),
              SizedBox(width: 8.w),
              Expanded(
                child: TextFormField(
                  controller: linkController,
                  decoration: InputDecoration(
                    labelText: 'رابط المنتج',
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                  ),
                  onChanged: (value) {
                    _editableLinks[index] =
                        _editableLinks[index].copyWith(link: value);
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.open_in_new, size: 20.sp),
                onPressed: () => _launchUrl(link.link),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child:TextFormField(
                  controller: piecesController,
                  decoration: InputDecoration(
                    labelText: 'الكمية',
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null) {
                      _editableLinks[index] =
                          _editableLinks[index].copyWith(pieces: parsed);
                      _updateTotalPieces(); // 🔹 Move update here
                    }
                  },
                ),

              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextFormField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظة',
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                  ),
                  onChanged: (value) {
                    _editableLinks[index] =
                        _editableLinks[index].copyWith(note: value);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _editableLinks.removeAt(index);
                    _updateTotalPieces();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }



Widget _buildStatusSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildDropdown(
              value: _status?.name,
              items: OrderStatus.values.map((e) => e.name).toList(),
              label: 'حالة الطلب',
              icon: Icons.charging_station,
              onChanged: (value) {
                setState(() {
                  _status = OrderStatus.values.firstWhere(
                    (e) => e.name == value,
                    orElse: () => OrderStatus.pending,
                  );
                });
              },
              validator: (value) => value == null ? 'هذا الحقل مطلوب' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    // Ensure value exists in items
    final validValue = items.contains(value) ? value : items.first;

    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      icon: _isSaving
          ? SizedBox(
              width: 24.sp,
              height: 24.sp,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(Icons.save, size: 24.sp),
      label: Text(
        _isSaving ? 'جاري الحفظ...' : 'حفظ التعديلات',
        style: TextStyle(fontSize: 16.sp),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      onPressed: _isSaving ? null : _saveChanges,
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboard,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      keyboardType: keyboard,
      maxLines: maxLines,
      readOnly: readOnly,
      validator: validator,
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الرابط')),
      );
    }
  }

  void _addNewProduct() {
    setState(() {
      _editableLinks.add(CartLink(link: "pending",  pieces: 0));
      _updateTotalPieces();
      _showProducts = true; // auto expand
    });
  }


  void _updateTotalPieces() {
    final totalPieces =
        _editableLinks.fold(0, (sum, link) => sum + (link.pieces));
    if (_piecesController.text != totalPieces.toString()) {
      _piecesController.text = totalPieces.toString();
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedOrder = widget.order.copyWith(
        customerName: _nameController.text.trim(),
        customerNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        note2: _note2Controller.text.trim(),
        totalPrice: double.tryParse(_priceController.text) ?? 0,
        pieceCount: int.tryParse(_piecesController.text) ?? 0,
        deposit: double.tryParse(_depositController.text) ?? 0,
        shippingCost: double.tryParse(_shippingCostController.text),
        note: _noteController.text.trim(),
        paymentMethod: _paymentMethod,
        shippingType: _shippingType,
        status: _status,
        cartLinks: _editableLinks,
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('orders1')
          .doc(updatedOrder.id)
          .update(updatedOrder.toFirestore());

      if (mounted) {
        Navigator.pop(context, updatedOrder);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }}
