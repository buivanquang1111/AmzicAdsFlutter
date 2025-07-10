import 'dart:io';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/shimmer/shimmer_banner_ads.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerDetectTestAds extends StatefulWidget {
  final String idAds;
  final bool config;
  final AdSize? adSize;
  final Function()? onAdLoaded;
  final Function()? onAdFailedToLoad;
  final Function()? onAdImpression;
  final Function()? onAdClicked;
  final Function()? onAdDisable;
  final Function()? onAdClosed;
  final Function() onCoreTechnologyTestAd;

  const BannerDetectTestAds({
    super.key,
    required this.idAds,
    required this.config,
    this.adSize,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdImpression,
    this.onAdClicked,
    this.onAdDisable,
    this.onAdClosed,
    required this.onCoreTechnologyTestAd,
  });

  @override
  State<BannerDetectTestAds> createState() => _BannerDetectTestAdsState();
}

class _BannerDetectTestAdsState extends State<BannerDetectTestAds> {
  final MethodChannel _bannerMethod = MethodChannel('banner_ads_detect_test_ads');

  bool isShowAd = false;
  bool isVisibility = true;

  @override
  void initState() {
    super.initState();
    _listenToAdEvents();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (widget.config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
      setState(() {
        isVisibility = false;
      });
    }
  }

  void _listenToAdEvents() async {
    try {
      _bannerMethod.setMethodCallHandler((call) async {
        final Map<String, dynamic>? event = call.arguments;
        switch (call.method) {
          case 'onRequestAds':
            print('banner_splash_platform --- Ad request');
            break;
          case 'onAdLoaded':
            print('banner_splash_platform --- Ad Loaded');
            widget.onAdLoaded?.call();
            break;
          case 'onAdClicked':
            print('banner_splash_platform --- Ad Clicked');
            widget.onAdClicked?.call();
            break;
          case 'onAdFailedToLoad':
            print('banner_splash_platform --- Ad Failed to Load: ${event?['error']}');
            widget.onAdFailedToLoad?.call();
            break;
          case 'onAdClosed':
            print('banner_splash_platform --- Ad Closed');
            widget.onAdClosed?.call();
            break;
          case 'onAdImpression':
            print('banner_splash_platform --- Ad Impression');
            widget.onAdImpression?.call();
            setState(() {
              isShowAd = true;
            });
            break;
          case 'coreTechnologyTestAd':
            print('banner_splash_platform --- coreTechnologyTestAd');
            widget.onCoreTechnologyTestAd?.call();
            break;
          default:
            print('banner_splash_platform --- Unknown event: ${call.method}');
        }
      });
    } catch (e) {
      print('banner_splash_platform --- Error listening to ad events: $e');
    }
  }

  AdSize getAdmobAdSize() {
    AdSize? adSize;
    Future(() async {
      adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        MediaQuery.sizeOf(context).width.truncate(),
      );
    });
    return adSize ?? AdSize.banner;
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisibility,
      child: Container(
        height: widget.adSize?.height.toDouble() ?? 60,
        width: widget.adSize?.width.toDouble() ?? double.infinity,
        decoration: const BoxDecoration(color: Colors.white),
        child: Stack(
          children: [
            if (Platform.isAndroid)
              AndroidView(
                viewType: 'banner_view_platform',
                creationParams: {
                  'adUnitId': widget.idAds,
                  'adSize': {
                    'width': widget.adSize?.width ?? getAdmobAdSize().width,
                    'height': widget.adSize?.height ?? getAdmobAdSize().height,
                  },
                },
                creationParamsCodec: const StandardMessageCodec(),
              ),
            if (!isShowAd) ShimmerBannerAds(),
          ],
        ),
      ),
    );
  }
}
