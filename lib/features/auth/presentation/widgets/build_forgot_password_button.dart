import 'package:butterfly_v2/core/themes/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class BuildForgotPasswordButton extends StatelessWidget {
  const BuildForgotPasswordButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {},
        child: Text(
         AppStrings2.forgotPassword,
          style: TextStyle(fontSize: 14.sp, color: Colors.black),
        ),
      ),
    );
  }
}
