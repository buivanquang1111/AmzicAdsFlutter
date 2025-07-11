import 'package:amazic_ads_flutter/ads/collapse_banner_ads.dart';
import 'package:amazic_ads_flutter/amazic_ads_flutter.dart';
import 'package:flutter/material.dart';

class CollapseBannerAdScreen extends StatefulWidget {
  const CollapseBannerAdScreen({super.key});

  @override
  State<CollapseBannerAdScreen> createState() => _CollapseBannerAdScreenState();
}

class _CollapseBannerAdScreenState extends State<CollapseBannerAdScreen> {
  CollapseBannerAds? collapseBannerAds;
  var canClick = true;
  final collapseKey = GlobalKey<CollapseBannerAdsState>();

  Future<void> dismissCollapse() async {
    if (collapseBannerAds == null) {
      return;
    }
    canClick = false;
    await collapseKey.currentState?.closeCollapse();
    await Future.delayed(const Duration(milliseconds: 800));
    canClick = true;
  }

  @override
  void initState() {
    super.initState();
    collapseBannerAds = CollapseBannerAds(
      key: collapseKey,
      idAds: 'ca-app-pub-3940256099942544/2014213617',
      type: CollapseBannerType.collapsible_bottom,
      config: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collapse banner example'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async{
            // ✅ Xử lý tại đây
            print('Custom back button pressed');
            await dismissCollapse();
            Navigator.pop(context); // nếu muốn quay lại
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(child: Text('Collapse banner ads')),
          collapseBannerAds ?? Container(),
        ],
      ),
    );
  }
}
