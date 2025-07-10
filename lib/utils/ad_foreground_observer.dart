import 'package:flutter/material.dart';

class AdForegroundObserver with WidgetsBindingObserver {
  final VoidCallback onShow;

  AdForegroundObserver({required this.onShow});

  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.removeObserver(this);
      onShow();
    }
  }
}
