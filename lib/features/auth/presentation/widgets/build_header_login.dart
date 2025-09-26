
import 'package:butterfly_v2/core/themes/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BuildHeader extends StatelessWidget {
  const BuildHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppStrings2.login,
          style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10.h),
        Text(AppStrings2.textUnderLogin, style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
      ],
    );
  }
}
