import 'package:amazic_ads_flutter/ads/collapsible_native_ads.dart';
import 'package:amazic_ads_flutter/ads/native_ads.dart';
import 'package:amazic_ads_flutter/call_api/call_api.dart';
import 'package:amazic_ads_flutter/manager_ad/preload_native_manager.dart';
import 'package:flutter/material.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail example app')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.amber,
              child: Column(
                children: [
                  // NativeAds(
                  //   idAds: 'ca-app-pub-3940256099942544/2247696110',
                  //   config: true,
                  //   height: 300,
                  //   factoryId: 'native_ad',
                  //   refreshSec: 5,
                  //   name: 'native_all_detail',
                  //   shimmer: NativeAdManager().showAd(
                  //     config: true,
                  //     nameIdAds: 'native_language',
                  //     height: 300,
                  //     adUnitId: CallApi.instance.getFirstIDByName('native_language'),
                  //     factoryId: 'native_ad',
                  //     // intervalReload: 5,
                  //   ),
                  // ),
                  Container(height: 200, color: Colors.greenAccent),
                ],
              ),
            ),
          ),
          CollapsibleNativeAds(
            idAds: 'ca-app-pub-3940256099942544/2247696110',
            config: true,
            factoryId: 'native_ad',
            refreshSec: 5,
            name: 'native_all_detail',
          ),
        ],
      ),
    );
  }
}
