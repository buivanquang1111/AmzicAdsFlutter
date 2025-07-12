import 'package:amazic_ads_flutter/ads/native_ads.dart';
import 'package:flutter/material.dart';

class NativeAdScreen extends StatelessWidget {
  const NativeAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Native example app')),
      body: NativeAds(
        idAds: 'ca-app-pub-3940256099942544/2247696110',
        config: true,
        height: 300,
        factoryId: 'native_ad',
      ),
    );
  }
}
