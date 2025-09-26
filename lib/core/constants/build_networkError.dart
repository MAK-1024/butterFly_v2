import 'dart:async';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class NetworkErrorManager {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  final ValueNotifier<List<ConnectivityResult>> connectionStatusNotifier = ValueNotifier([ConnectivityResult.none]);

  bool get isConnected => !connectionStatusNotifier.value.contains(ConnectivityResult.none);

  void initialize() {
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void dispose() {
    _subscription.cancel();
    connectionStatusNotifier.dispose();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateStatus(result);
    } catch (e) {
      developer.log('Error checking connectivity', error: e);
    }
  }

  void _updateStatus(List<ConnectivityResult> result) {
    connectionStatusNotifier.value = result;
  }

  Widget buildNoConnectionScreen(VoidCallback onRetry) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.red),
              SizedBox(height: 16.h),
              Text(
                'لا يوجد اتصال بالإنترنت',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.cairo().fontFamily),
              ),
              SizedBox(height: 8.h),
              Text(
                'الرجاء التحقق من اتصالك بالشبكة والمحاولة مرة أخرى',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.sp, fontFamily: GoogleFonts.cairo().fontFamily),
              ),
              SizedBox(height: 20.h),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontSize: 16.sp, color: Colors.black, fontFamily: GoogleFonts.cairo().fontFamily),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
