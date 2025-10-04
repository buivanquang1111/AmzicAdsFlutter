import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/amazic_ads_flutter.dart';
import 'package:amazic_ads_flutter/call_api/call_api.dart';
import 'package:amazic_ads_flutter/utils/remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'banner_ad_screen.dart';
import 'collapse_banner_ad_screen.dart';
import 'main.dart';
import 'native_ad_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();

    //load truoc ads reward all
    Admob.instance.loadRewardAdConsecutive(
      idAds: 'ca-app-pub-3940256099942544/5224354917',
      config: true,
    );

    _preload();
  }

  void _preload() {
    NativeAdManager().preloadAd(
      adUnitId: CallApi.instance.getFirstIDByName('native_language'),
      config: false,
      nameIdAds: 'native_language',
      factoryId: 'native_ad',
      onAdLoaded: () {
      },
      onAdFailed: (error) {
      },
    );
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
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Running on: $_platformVersion\n'),
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        print(
                          'check_ads_splash --- inter: ${InterAdsManager.instance.mInterstitialAdSplash}, open: ${AppOpenManager.instance.mAppOpenAdSplash}',
                        );

                        Admob.instance.showAdsSplash(
                          navigatorKey: navigatorKey,
                          onNext: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BannerAdScreen()),
                            );
                          },
                        );
                      },
                      child: Center(
                        child: Container(
                          height: 56,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.greenAccent,
                          ),
                          child: Center(
                            child: Text('show banner ads', textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NativeAdScreen()),
                        );
                      },
                      child: Center(
                        child: Container(
                          height: 56,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.greenAccent,
                          ),
                          child: Center(
                            child: Text('show native ads', textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        Admob.instance.loadAndShowInterInterval(
                          navigatorKey: navigatorKey,
                          idAds: 'ca-app-pub-3940256099942544/1033173712',
                          config: true,
                          isInterAll: true,
                          name: 'inter_all',
                          onAdDisable: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NativeAdScreen()),
                            );
                          },
                          onAdFailedToLoad: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NativeAdScreen()),
                            );
                          },
                          onAdFailedToShow: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NativeAdScreen()),
                            );
                          },
                          onAdDismiss: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NativeAdScreen()),
                            );
                          },
                        );
                      },
                      child: Center(
                        child: Container(
                          height: 56,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.greenAccent,
                          ),
                          child: Center(child: Text('show inter ads', textAlign: TextAlign.center)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CollapseBannerAdScreen()),
                        );
                      },
                      child: Center(
                        child: Container(
                          height: 56,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.greenAccent,
                          ),
                          child: Center(
                            child: Text('show collapse banner ads', textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        Admob.instance.loadAndShowRewardAds(
                          navigatorKey: navigatorKey,
                          idAds: 'ca-app-pub-3940256099942544/5224354917',
                          config: true,
                          name: 'reward_all',
                          onAdDisable: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CollapseBannerAdScreen()),
                            );
                          },
                          onAdDismiss: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CollapseBannerAdScreen()),
                            );
                          },
                        );
                      },
                      child: Center(
                        child: Container(
                          height: 56,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.greenAccent,
                          ),
                          child: Center(
                            child: Text('show reward ads', textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        Admob.instance.loadAndShowAppOpenAds(
                          navigatorKey: navigatorKey,
                          idAds: 'ca-app-pub-3940256099942544/9257395921',
                          config: true,
                          name: 'app_open_all',
                          onAdDisable: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NativeAdScreen()),
                            );
                          },
                          onAdFailedToLoad: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NativeAdScreen()),
                            );
                          },
                          onAdFailedToShow: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NativeAdScreen()),
                            );
                          },
                          onAdDismiss: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NativeAdScreen()),
                            );
                          },
                        );
                      },
                      child: Center(
                        child: Container(
                          height: 56,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.greenAccent,
                          ),
                          child: Center(
                            child: Text('show App Open ads', textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        Admob.instance.showRewardConsecutive(
                          idAds: 'ca-app-pub-3940256099942544/5224354917',
                          config: true,
                          count: 2,
                          name: 'reward2_all',
                          onCompleted: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NativeAdScreen()),
                            );
                          },
                        );
                      },
                      child: Center(
                        child: Container(
                          height: 56,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.greenAccent,
                          ),
                          child: Center(
                            child: Text('show 2 reward ads', textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          NativeAds(
            idAds: CallApi.instance.getFirstIDByName('native_language'),
            config: RemoteConfig.getBool('native_ads'),
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
