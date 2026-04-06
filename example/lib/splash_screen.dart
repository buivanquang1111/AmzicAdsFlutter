import 'dart:async';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/amazic_ads_flutter.dart';
import 'package:amazic_ads_flutter/call_api/call_api.dart';
import 'package:amazic_ads_flutter/utils/remote_config.dart';
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
    Admob.instance.setUseAdPreloading(true);
    Admob.instance.setUseNativeAfterInter(true);

    await Admob.instance.init(
      linkServer: '',
      appId: '',
      packageName: '',
      navigatorKey: navigatorKey,
      nameIddAdsResume: 'resume_wb',
      nameResumeConfig: 'resume_wb',
      isShowWelComeScreenAfterAppOpenAds: true,
      onGotoScreenWelcomeBack: () {
        Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(builder: (context) => WelcomeBackScreen()),
        );
      },
      nameIdAdsAppOpenSplash: 'open_splash',
      nameIdAdsInterSplash: 'inter_splash',
      nameIdAdsNativeAfterInter: 'native_intro',
      nameConfigAppOpenSplash: 'open_splash',
      nameConfigInterSplash: 'inter_splash',
      nameConfigNativeAfterInter: 'native_intro',
      nameRateAoa: 'rate_aoa_inter_splash',
      onNext: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      },
      nameIntervalBetweenInter: 'interval_between_interstitial',
      nameIntervalFromStart: 'interval_interstitial_from_start',
      nameIntervalInterAll: 'interval_inter_all',
      onStartLoadBanner: () {},
      remoteConfigKeys: [
        RemoteConfigKey(name: 'show_ads', defaultValue: true, valueType: bool),
        RemoteConfigKey(name: 'banner_ads', defaultValue: true, valueType: bool),
        RemoteConfigKey(name: 'native_intro', defaultValue: true, valueType: bool),
        RemoteConfigKey(name: 'collap_reload_interval', defaultValue: 10, valueType: int),
        RemoteConfigKey(name: 'collapse_banner', defaultValue: true, valueType: bool),
        RemoteConfigKey(name: 'inter_ads', defaultValue: true, valueType: bool),
        RemoteConfigKey(name: 'inter_splash', defaultValue: true, valueType: bool),
        RemoteConfigKey(name: 'interval_between_interstitial', defaultValue: 20, valueType: int),
        RemoteConfigKey(name: 'interval_inter_all', defaultValue: 30, valueType: int),
        RemoteConfigKey(name: 'interval_interstitial_from_start', defaultValue: 5, valueType: int),
        RemoteConfigKey(name: 'interval_reload_native', defaultValue: 5, valueType: int),
        RemoteConfigKey(name: 'native_ads', defaultValue: true, valueType: bool),
        RemoteConfigKey(name: 'open_splash', defaultValue: true, valueType: bool),
        RemoteConfigKey(name: 'rate_aoa_inter_splash', defaultValue: '0_100', valueType: String),
        RemoteConfigKey(name: 'resume_wb', defaultValue: true, valueType: bool),
      ],
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
