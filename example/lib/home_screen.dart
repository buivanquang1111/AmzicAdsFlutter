import 'package:amazic_ads_flutter/admob.dart';
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
      appBar: AppBar(title: const Text('Home example app')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Running on: $_platformVersion\n'),
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BannerAdScreen()),
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
                  child: Center(child: Text('show banner ads', textAlign: TextAlign.center)),
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
                  child: Center(child: Text('show native ads', textAlign: TextAlign.center)),
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
                  child: Center(child: Text('show reward ads', textAlign: TextAlign.center)),
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
                  child: Center(child: Text('show App Open ads', textAlign: TextAlign.center)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
