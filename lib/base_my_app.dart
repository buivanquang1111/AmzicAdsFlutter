import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract class BaseMyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const BaseMyApp({super.key, required this.navigatorKey});

  @override
  BaseMyAppState createState();
}

abstract class BaseMyAppState<T extends BaseMyApp> extends State<T> {
  @override
  void initState() {
    super.initState();
    initAdmob();
  }

  Widget buildScreen(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return buildScreen(context);
  }

  Future<void> initAdmob() async {
    MobileAds.instance.initialize().then((value) {
      print("=== Mediation AdMob Initialization Status ===");
      value.adapterStatuses.forEach((key, status) {
        final state = status.state;
        final description = status.description;

        print("  Adapter: $key");
        print("  State: $state");
        print("  Description: $description");

        if (state == AdapterInitializationState.notReady) {
          print("  ⚠️ This adapter is NOT READY. Check SDK setup, app ID, or initialization code.");
        } else if (state == AdapterInitializationState.ready) {
          print("  ✅ Ready to serve ads.");
        }
      });
      print("=== End of Adapter Status ===");
    });
  }
}
