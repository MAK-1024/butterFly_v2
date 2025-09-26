import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:toastification/toastification.dart';

import '../../../../core/themes/colors.dart';
import '../../../../core/themes/strings.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  List<String> _selectedRoles = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  Future<void> _createUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) throw Exception('Not authenticated');

      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminUser.uid)
          .get();

      if (adminDoc.data()?['role'] is List) {
        if (!(adminDoc.data()?['role'] as List).contains('admin')) {
          throw Exception('Admin privileges required');
        }
      } else if (adminDoc.data()?['role'] != 'admin') {
        throw Exception('Admin privileges required');
      }

      final auth = FirebaseAuth.instance;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();

      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateProfile(displayName: name);

      // Sign back in as admin (assumes fixed password for admin, change accordingly)
      await auth.signInWithEmailAndPassword(
        email: adminUser.email!,
        password: 'admin2025@1',
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'userName': name,
        'password': password,
        'role': _selectedRoles,
        'createdBy': adminUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isDisabled': false,
        'forceLogout': false,
      });

      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('تم انشاء الحساب بنجاح'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(' الحساب :  $email'),
              const SizedBox(height: 10),
              Text(' كلمة المرور : $password'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r)),
                        textStyle: TextStyle(
                            fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                      icon: const Icon(Icons.copy, color: Colors.white),
                      label: const Text('نسخ الحساب',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: email));
                        Clipboard.setData(ClipboardData(text: password));
                        toastification.show(
                          type: ToastificationType.info,
                          context: context,
                          title: Text("تم نسخ الحساب وكلمة المرور الى الحافظة"),
                          autoCloseDuration: Duration(seconds: 5),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('موافق', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );

      // Clear form
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _selectedRoles.clear();

      toastification.show(
        type: ToastificationType.success,
        context: context,
        title: Text("تم انشاء الحساب بنجاح"),
        autoCloseDuration: Duration(seconds: 5),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      toastification.show(
        type: ToastificationType.error,
        context: context,
        title: Text('Error: ${e.message ?? 'Unknown error'}'),
        autoCloseDuration: Duration(seconds: 5),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      toastification.show(
        type: ToastificationType.error,
        context: context,
        title: Text('Error: $e'),
        autoCloseDuration: Duration(seconds: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CustomTextField(
                    hintText: 'الاسم',
                    borderRadius: 8,
                    borderColor: AppColors.fieldText,
                    controller: _nameController,
                    prefixIcon: Icons.drive_file_rename_outline_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings2.namelValidation;
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    hintText: 'الحساب',
                    borderRadius: 8,
                    borderColor: AppColors.fieldText,
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings2.emailValidation;
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    hintText: 'كلمة المرور',
                    borderRadius: 8,
                    borderColor: AppColors.fieldText,
                    controller: _passwordController,
                    prefixIcon: Icons.lock_open,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings2.passwordValidation;
                      }
                      return null;
                    },
                  ),
                  FormField<List<String>>(
                    validator: (value) {
                      if (_selectedRoles.isEmpty) {
                        return AppStrings2.roleValidation;
                      }
                      return null;
                    },
                    builder: (FormFieldState<List<String>> state) {
                      final roles = ['user', 'delivery', 'manager', 'coordinator'
                          ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'اختر أدوار المستخدم',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...roles.map((role) {
                            return CheckboxListTile(
                              title: Text(role),
                              value: _selectedRoles.contains(role),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (isSelected) {
                                setState(() {
                                  if (isSelected == true) {
                                    _selectedRoles.add(role);
                                  } else {
                                    _selectedRoles.remove(role);
                                  }
                                  state.didChange(_selectedRoles);
                                });
                              },
                            );
                          }).toList(),
                          if (state.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                state.errorText!,
                                style: TextStyle(
                                    color: AppColors.errorColor, fontSize: 14),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator()
                      : CustomMaterialButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _createUser();
                      }
                    },
                    buttonText: 'انشاء مستخدم جديد',
                    buttonColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
