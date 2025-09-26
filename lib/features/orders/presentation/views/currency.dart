import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CurrencyConverterScreen extends StatefulWidget {
  @override
  _CurrencyConverterScreenState createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final usdController = TextEditingController();
  final rateController = TextEditingController();
  String result = '';

  void convertCurrency() {
    double usd = double.tryParse(usdController.text) ?? 0;
    double rate = double.tryParse(rateController.text) ?? 0;
    double lyd = usd * rate;
    setState(() {
      result = '$usd دولار = $lyd دينار ليبي';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('محول العملات'),
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: usdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ بالدولار',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  prefixIcon: Icon(Icons.attach_money, color: Colors.black),
                ),
              ),
              SizedBox(height: 15.h),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'سعر الصرف (دولار إلى دينار)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  prefixIcon: Icon(Icons.currency_exchange, color: Colors.black),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: convertCurrency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    textStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  child: Text('تحويل', style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                result,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
