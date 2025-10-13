import 'package:amazic_ads_flutter/ads/native_ads.dart';
import 'package:amazic_ads_flutter/amazic_ads_flutter.dart';
import 'package:amazic_ads_flutter/call_api/call_api.dart';
import 'package:amazic_ads_flutter_example/detail_screen.dart';
import 'package:flutter/material.dart';

class NativeAdScreen extends StatefulWidget {
  const NativeAdScreen({super.key});

  @override
  State<NativeAdScreen> createState() => _NativeAdScreenState();
}

class _NativeAdScreenState extends State<NativeAdScreen> {
  bool isShowAdsNew = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Native example app')),
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              // Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen()));
              setState(() {
                isShowAdsNew = !isShowAdsNew;
              });
            },
            child: Center(child: Text('go to detail')),
          ),
          Text('----------Preload Native ad----------'),
          isShowAdsNew == true
              ? NativeAdManager().showAd(
                  key: ValueKey('native_language'),
                  config: true,
                  nameIdAds: 'native_language',
                  height: 300,
                  adUnitId: CallApi.instance.getFirstIDByName('native_language'),
                  factoryId: 'native_ad',
                  intervalReload: 5,
                )
              : NativeAdManager().showAd(
                  key: ValueKey('native_intro'),
                  config: true,
                  nameIdAds: 'native_intro',
                  height: 300,
                  adUnitId: CallApi.instance.getFirstIDByName('native_intro'),
                  factoryId: 'native_ad',
                  intervalReload: 5,
                ),
          Text('----------Native ad----------'),
          NativeAds(
            idAds: 'ca-app-pub-3940256099942544/2247696110',
            config: true,
            height: 300,
            factoryId: 'native_ad',
            refreshSec: 5,
            name: 'native_all',
          ),
        ],
      ),
    );
  }
}
