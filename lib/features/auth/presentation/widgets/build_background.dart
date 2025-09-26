import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/themes/colors.dart';


class BuildBackground extends StatelessWidget {
  const BuildBackground ({super.key});

  @override
  Widget build(BuildContext context) {
     {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          height: 400.h,
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -62.h,
                left: -45.w,
                child: Container(
                  width: 220,
                  height: 220,
                  child: CircleAvatar(
                    radius: 80.r,
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                top: -166.h,
                left: 157.w,
                child: Container(
                  width: 280,
                  height: 280,
                  child: CircleAvatar(
                    radius: 60.r,
                    backgroundColor: AppColors.secondry,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

  }
}
