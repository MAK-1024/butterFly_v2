import 'package:butterfly_v2/core/themes/strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_router/routes.dart';
import '../../../../core/constants/AppStrings.dart';
import '../../../../core/constants/DI/service_locator.dart';
import '../../../../core/themes/colors.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';
import '../widgets/build_background.dart';
import '../widgets/build_header_login.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider<AuthCubit>(
        create: (context) => sl<AuthCubit>(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              BuildBackground(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Center(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 100.h),
                          BuildHeader(),
                          SizedBox(height: 40.h),
                          CustomTextField(
                            hintText: AppStrings2.loginTextFieldEmail,
                            borderRadius: 8,
                            borderColor: AppColors.fieldText,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings2.emailValidation;
                              }
                              return null;
                            },
                            prefixIcon: Icons.person,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            controller: _emailController,
                          ),
                          SizedBox(height: 20.h),
                          CustomTextField(
                            hintText: AppStrings2.loginTextFieldPassword,
                            borderRadius: 8,
                            borderColor: AppColors.fieldText,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings2.passwordValidation;
                              }
                              return null;
                            },
                            prefixIcon: Icons.key,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
                            isPassword: true,
                            controller: _passwordController,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ResetPasswordScreen(),
                                ),
                              );
                              // Or if using go_router:
                              // GoRouter.of(context).push(AppRouter.resetPasswordPath);
                            },
                            child: Text(
                              AppStrings2.forgotPassword,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          SizedBox(height: 30.h),
                          BlocConsumer<AuthCubit, AuthState>(
                            listener: (context, state) {
                              if (state is AuthAuthenticated) {
                                GoRouter.of(context)
                                    .pushReplacement(AppRouter.mainOrderScreen);
                                // toastification.show(
                                //   type: ToastificationType.success,
                                //   context: context,
                                //   title: Text("تم تسجيل الدخول بنجاح"),
                                //   autoCloseDuration: Duration(seconds: 5),
                                // );
                              } else if (state is AuthError) {
                                // Padding(
                                //   padding: EdgeInsets.only(top: 8.h),
                                //   child: Text(
                                //     state.message,
                                //     style: TextStyle(
                                //       color: Colors.red,
                                //       fontSize: 14.sp,
                                //     ),
                                //     textAlign: TextAlign.center,
                                //   ),
                                // );
                              }
                            },


                            builder: (context, state) {
                              return CustomMaterialButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    String email = _emailController.text.trim();
                                    String password =
                                        _passwordController.text.trim();
                                    context
                                        .read<AuthCubit>()
                                        .signIn(email, password);
                                  }
                                },
                                buttonText: AppStrings2.login,
                                buttonColor: AppColors.primary,
                              );
                            },
                          ),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class ResetPasswordScreen extends StatelessWidget {
  ResetPasswordScreen({super.key});

  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
        ),
        body: Padding(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40.h),
                Text(
                  "إعادة تعيين كلمة المرور",
                  style: TextStyle(fontSize: 16.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30.h),
                CustomTextField(
                  hintText: "البريد الالكتروني",
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings2.emailValidation;
                    }
                    return null;
                  },
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress, borderRadius: 30, borderColor: Colors.black,
                ),
                SizedBox(height: 30.h),
                BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state is AuthPasswordResetSent) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("تم ارسال الرابط , الرجاء التحقق"),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      Navigator.of(context).pop();
                    } else if (state is AuthError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                    }
                  },
                  builder: (context, state) {
                    return Column(
                      children: [
                        CustomMaterialButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthCubit>().resetPassword(
                                _emailController.text.trim(),
                              );
                            }
                          },
                          buttonText: "تأكيد",
                          buttonColor: AppColors.primary,
                        ),
                        if (state is AuthLoading)
                          Padding(
                            padding: EdgeInsets.only(top: 16.h),
                            child: const CircularProgressIndicator(),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}