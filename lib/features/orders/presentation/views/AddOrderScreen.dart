import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/app_router/routes.dart';
import '../../../../core/constants/AppStrings.dart';
import '../../data/model/CartLinkModel.dart';
import '../../data/model/orderModel.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';

class AddOrderScreen extends StatelessWidget {
  final OrderModel? orderToEdit;
  final String? initialName;
  final String? initialPhone;
  final String? initialAddress;

  const AddOrderScreen(
      {super.key,
      this.orderToEdit,
      this.initialName,
      this.initialPhone,
      this.initialAddress});

  @override
  Widget build(BuildContext context) {
    return _AddOrderView(
      orderToEdit: orderToEdit,
      initialName: initialName,
      initialPhone: initialPhone,
      initialAddress: initialAddress,
    );
  }
}

class _AddOrderView extends StatefulWidget {
  final OrderModel? orderToEdit;
  final String? initialName;
  final String? initialPhone;
  final String? initialAddress;

  const _AddOrderView(
      {this.orderToEdit,
      this.initialName,
      this.initialPhone,
      this.initialAddress});

  @override
  State<_AddOrderView> createState() => _AddOrderViewState();
}

class _AddOrderViewState extends State<_AddOrderView> {
  @override
  @override
  void initState() {
    _fetchUserData();
    super.initState();

    if (widget.orderToEdit != null) {
      final order = widget.orderToEdit!;
      _nameController.text = order.customerName;
      _phoneController.text = order.customerNumber;
      _addressController.text = order.address;
      _note2Controller.text = order.note2 ?? '';
      _totalPriceController.text = order.totalPrice.toString();
      _depositController.text = order.deposit.toString();
      _noteController.text = order.note ?? '';
      _orderStatus = order.status;

      _cartItems = order.cartLinks
          .map((link) => CartItemInput()
        ..linkController.text = link.link
        ..qtyController.text = link.pieces.toString()
        ..noteController.text = link.note ?? '')
          .toList();
    } else {
      // هنا في حالة إعادة الطلب من طلب قديم
      if (widget.initialName != null) _nameController.text = widget.initialName!;
      if (widget.initialPhone != null) _phoneController.text = widget.initialPhone!;
      if (widget.initialAddress != null) _addressController.text = widget.initialAddress!;
    }
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userName = user.displayName ?? "موظف";
        setState(() {
          _empController.text = userName;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _empController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _depositController = TextEditingController();
  final _noteController = TextEditingController();
  final _note2Controller = TextEditingController();

  List<CartItemInput> _cartItems = [CartItemInput()];
  OrderStatus _orderStatus = OrderStatus.pending;

  @override
  void dispose() {
    _empController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _totalPriceController.dispose();
    _depositController.dispose();
    _noteController.dispose();
    _note2Controller.dispose();
    for (var item in _cartItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addCartItem() {
    setState(() => _cartItems.add(CartItemInput()));
  }

  void _removeCartItem(int index) {
    if (_cartItems.length > 1) {
      setState(() {
        _cartItems[index].dispose();
        _cartItems.removeAt(index);
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _empController.clear();
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _totalPriceController.clear();
    _depositController.clear();
    _noteController.clear();
    _note2Controller.clear();
    setState(() {
      _cartItems = [CartItemInput()];
      _orderStatus = OrderStatus.pending;
    });
  }

  Future<void> _submitOrder() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<OrderCubit>();
    if (cubit.state is OrderLoading) return;

    final order = OrderModel(
        id: widget.orderToEdit?.id ?? '',
        customerName: _nameController.text.trim(),
        userName: _empController.text.trim() ?? 'Current User',
        customerNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        note2: _note2Controller.text.trim(),
        totalPrice: double.tryParse(_totalPriceController.text) ?? 0.0,
        deposit: double.tryParse(_depositController.text) ?? 0.0,
        status: _orderStatus,
        createdAt: widget.orderToEdit?.createdAt ?? DateTime.now(),
        cartLinks: _cartItems
            .map((item) => CartLink(
                  link: item.linkController.text.trim(),
                  pieces: int.tryParse(item.qtyController.text) ?? 0,
                  note: item.noteController.text.trim(),
                ))
            .toList(),
        pieceCount: _cartItems.fold(
          0,
          (sum, item) => sum + (int.tryParse(item.qtyController.text) ?? 0),
        ),
        note: _noteController.text.trim(),
        isSelected: false,
        finalPrice: widget.orderToEdit?.finalPrice,
        linkedOrderIds: widget.orderToEdit?.linkedOrderIds,
        isHidden: false);

    if (widget.orderToEdit == null) {
      await cubit.createOrder(order);
      cubit.loadOrdersByStatus(OrderStatus.pending);
    } else {
      final updates = {
        'customerName': order.customerName,
        'customerNumber': order.customerNumber,
        'address': order.address,
        'totalPrice': order.totalPrice,
        'deposit': order.deposit,
        'cartLinks': order.cartLinks.map((link) => link.toFirestore()).toList(),
        'pieceCount': order.pieceCount,
        'note': order.note,
        'note2': order.note2,
      };
      await cubit.updateOrderDetails(order.id, updates);
    }

    if (!mounted) return;
    GoRouter.of(context).go(AppRouter.mainOrderScreen);
    GoRouter.of(context).pop();

  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocConsumer<OrderCubit, OrderState>(
          listener: (context, state) {
            if (state is OrderOperationSuccess) {
              toastification.show(
                type: ToastificationType.success,
                context: context,
                title: Text(AppStrings.orderCreatedSuccess),
                autoCloseDuration: Duration(seconds: 5),
              );
              if (widget.orderToEdit == null) {
                _resetForm();
              }
            }
            if (state is OrderFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            return AbsorbPointer(
              absorbing: state is OrderLoading,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCustomerSection(),
                          SizedBox(height: 24.h),
                          _buildSubmitButton(),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                  ),
                  if (state is OrderLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(AppStrings.customerInfo),
            SizedBox(height: 12.h),
            _formField(
              controller: _empController,
              label: AppStrings.employeeName,
              icon: Icons.person,
              readOnly: true,
            ),
            SizedBox(height: 12.h),
            _formField(
              controller: _nameController,
              label: AppStrings.customerName,
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.requiredField;
                }
                if (value.length < 3) {
                  return 'الاسم يجب ان يكون على الاقل 3 حروف';
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _formField(
              controller: _phoneController,
              label: AppStrings.phoneNumber,
              icon: Icons.phone,
              keyboard: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.requiredField;
                }
                final phoneRegex = RegExp(r'^09[1-4]\d{7}$');
                if (!phoneRegex.hasMatch(value)) {
                  return 'يجب ان يكون 091/092/093/094 متبوع ب 7 ارقام';
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _formField(
              controller: _addressController,
              label: AppStrings.address,
              icon: Icons.location_on,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.requiredField;
                }
                if (value.length < 3) {
                  return 'العنوان يجب ان يكون على الاقل 3 حروف';
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _formField(
              controller: _note2Controller,
              label: AppStrings.notesOptional,
              icon: Icons.note,
              maxLines: 2,
            ),
            SizedBox(height: 12.h),
            _formField(
              controller: _totalPriceController,
              label: AppStrings.totalPrice,
              icon: Icons.attach_money,
              keyboard: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.requiredField;
                }
                if (double.tryParse(value) == null) {
                  return AppStrings.enterValidNumber;
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            _formField(
              controller: _depositController,
              label: AppStrings.depositAmount,
              icon: Icons.payment,
              keyboard: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  // Check if valid number
                  final deposit = double.tryParse(value);
                  if (deposit == null) {
                    return AppStrings.enterValidNumber;
                  }

                  // Check against total price
                  final totalPrice =
                      double.tryParse(_totalPriceController.text);
                  if (totalPrice != null && deposit > totalPrice) {
                    return 'العربون يجب ان يكون اقل من السعر الادجمالي';
                  }
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            ..._cartItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _formField(
                            controller: item.linkController,
                            label: AppStrings.productLink,
                            icon: Icons.link,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.requiredField;
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 8.w),
                        SizedBox(
                          width: 70.w,
                          child: _formField(
                            controller: item.qtyController,
                            label: AppStrings.quantity,
                            keyboard: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.requiredField;
                              }
                              if (int.tryParse(value) == null) {
                                return AppStrings.enterValidNumber;
                              }

                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeCartItem(index),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _formField(
                      controller: item.noteController,
                      label: AppStrings.notesOptional,
                      icon: Icons.note,
                      maxLines: 2,
                    ),
                    if (index < _cartItems.length - 1)
                      Divider(height: 24.h, thickness: 1),
                  ],
                ),
              );
            }).toList(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addCartItem,
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.addAnotherItem),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(AppStrings.orderNotes),
            SizedBox(height: 12.h),
            _formField(
              controller: _noteController,
              label: AppStrings.notesOptional,
              icon: Icons.note,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitOrder,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          AppStrings.createOrder,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
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
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: 16.h,
          horizontal: 16.w,
        ),
      ),
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class CartItemInput {
  final linkController = TextEditingController();
  final qtyController = TextEditingController();
  final noteController = TextEditingController();

  void dispose() {
    linkController.dispose();
    qtyController.dispose();
    noteController.dispose();
  }
}
