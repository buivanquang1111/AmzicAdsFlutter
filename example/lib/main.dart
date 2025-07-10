import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter_example/banner_ad_screen.dart';
import 'package:amazic_ads_flutter_example/collapse_banner_ad_screen.dart';
import 'package:amazic_ads_flutter_example/home_screen.dart';
import 'package:amazic_ads_flutter_example/native_ad_screen.dart';
import 'package:amazic_ads_flutter_example/splash_screen.dart';
import 'package:amazic_ads_flutter_example/welcome_back_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await Admob.instance.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: SplashScreen(),
      ),
    );
  }
}
