import 'package:amazic_ads_flutter/ads/banner_ads.dart';
import 'package:flutter/material.dart';

class BannerAdScreen extends StatelessWidget {
  const BannerAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banner example app')),
      body: Column(
        children: [
          Expanded(child: Text('Banner ads')),
          BannerAds(idAds: 'ca-app-pub-3940256099942544/6300978111', config: true),
        ],
      ),
    );
  }
}
