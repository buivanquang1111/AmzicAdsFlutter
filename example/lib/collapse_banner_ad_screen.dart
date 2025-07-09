import 'package:amazic_ads_flutter/ads/collapse_banner_ads.dart';
import 'package:amazic_ads_flutter/amazic_ads_flutter.dart';
import 'package:flutter/material.dart';

class CollapseBannerAdScreen extends StatelessWidget {
  const CollapseBannerAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collapse banner example')),
      body: Column(
        children: [
          Expanded(child: Text('Collapse banner ads')),
          CollapseBannerAds(
            idAds: 'ca-app-pub-3940256099942544/2014213617',
            type: CollapseBannerType.collapsible_bottom,
            config: true,
          ),
        ],
      ),
    );
  }
}
