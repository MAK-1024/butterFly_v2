import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/DI/service_locator.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';

class UsersScreen extends StatelessWidget {
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'إدارة الحسابات',
            style: TextStyle(fontSize: 20.sp),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: BlocProvider(
            create: (_) => sl<AuthCubit>()..fetchUsers(),
            child: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: ${state.message}')),
                  );
                  print(state.message);
                }
              },
              builder: (context, state) {
                if (state is AuthLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is AuthUsersLoaded) {
                  final users = state.users;
                  if (users.isEmpty) {
                    return Center(child: Text('لا يوجد مستخدمين متاحين.'));
                  }
                  return Column(
                    children: [
                      // Uncomment to enable search
                      // Padding(
                      //   padding: EdgeInsets.only(bottom: 16.h),
                      //   child: TextField(
                      //     controller: searchController,
                      //     decoration: InputDecoration(
                      //       labelText: 'ابحث عن المستخدمين',
                      //       labelStyle: TextStyle(fontSize: 14.sp),
                      //       border: OutlineInputBorder(),
                      //       contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      //     ),
                      //     onChanged: (query) {
                      //       context.read<AuthCubit>().searchUsers(query);
                      //     },
                      //   ),
                      // ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            // Show roles as comma separated string
                            final roleText = (user.role is List<String>)
                                ? (user.role as List<String>).join(', ')
                                : user.role.toString();

                            return Card(
                              margin: EdgeInsets.only(bottom: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 4,
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16.w),
                                title: Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      roleText,
                                      style: TextStyle(fontSize: 12.sp, color: Colors.green),
                                    ),

                                    IconButton(
                                      icon: Icon(
                                        user.forceLogout ? Icons.lock : Icons.lock_open,
                                        color: user.forceLogout ? Colors.green : Colors.redAccent,
                                      ),
                                      tooltip: user.forceLogout ? 'إلغاء الحظر' : 'تسجيل خروج إجباري',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text('تأكيد'),
                                            content: Text(user.forceLogout
                                                ? 'هل تريد إعادة تمكين دخول هذا المستخدم؟'
                                                : 'هل تريد تسجيل خروج المستخدم هذا إجباريًا؟'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(false),
                                                child: Text('إلغاء'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(true),
                                                child: Text('نعم'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          if (user.forceLogout) {
                                            // إلغاء الحظر
                                            await context.read<AuthCubit>().toggleForceLogoutUser(user.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('تم إعادة تمكين دخول المستخدم')),
                                            );
                                          } else {
                                            // فرض تسجيل الخروج
                                            await context.read<AuthCubit>().toggleForceLogoutUser(user.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('تم تفعيل تسجيل الخروج الإجباري للمستخدم')),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return Center(child: Text('لا يوجد مستخدمين متاحين.'));
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
