import 'dart:async';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter_example/home_screen.dart';
import 'package:amazic_ads_flutter_example/welcome_back_screen.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    await Future.delayed(Duration(seconds: 2));
    await Admob.instance.init(
      navigatorKey: navigatorKey,
      idAdsResume: 'ca-app-pub-3940256099942544/9257395921',
      idAdsAppOpenSplash: 'ca-app-pub-3940256099942544/9257395921',
      idAdsInterSplash: 'ca-app-pub-3940256099942544/1033173712',
      configAppOpenSplash: true,
      configInterSplash: true,
      intervalBetweenInter: 20,
      intervalFromStart: 10,
      rateAoa: '0_100',
      onNext: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      },
      isShowWelComeScreenAfterAppOpenAds: true,
      onGotoScreenWelcomeBack: () {
        Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(builder: (context) => WelcomeBackScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banner example app')),
      body: Column(children: [Center(child: Text('splash screen'))]),
    );
  }
}
