import 'package:flutter/material.dart';

class CustomMaterialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonText;
  final Color buttonColor;
  final double height;
  final double minWidth;
  final Icon? icon;

  const CustomMaterialButton({
    Key? key,
    required this.onPressed,
    required this.buttonText,
    required this.buttonColor,
    this.height = 48.0,
    this.minWidth = 320.0,
    this.icon,
    bool? isLoading = true,  Color? textColor,


  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      color: buttonColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
      height: height,
      minWidth: minWidth,
      child: Text(buttonText,style: TextStyle(color: Colors.white , fontWeight: FontWeight.bold),),


    );
  }
}
