import 'package:amazic_ads_flutter/amazic_ads_flutter_platform_interface.dart';
import 'package:flutter/material.dart';

import '../call_api/call_api.dart';
import '../manager_ad/preload_native_manager.dart';
import '../utils/remote_config.dart';

class NativeAfterInterScreen extends StatefulWidget {
  final String adsKey;
  final String remoteKey;
  final Function() onClose;

  const NativeAfterInterScreen({
    super.key,
    required this.adsKey,
    required this.remoteKey,
    required this.onClose
  });

  @override
  State<NativeAfterInterScreen> createState() => _NativeAfterInterScreenState();
}

class _NativeAfterInterScreenState extends State<NativeAfterInterScreen> {

  @override
  void initState() {
    super.initState();

    AmazicAdsFlutterPlatform.instance.onNativeAfterInterClose = () {
      print("admob_ads: Native After Inter - click close");
      if(Navigator.canPop(context)){
        Navigator.pop(context);
      }

      widget.onClose();
    };

  }

  @override
  void dispose() {
    super.dispose();
    AmazicAdsFlutterPlatform.instance.onNativeAfterInterClose = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          NativeAdManager().showAd(
            config: RemoteConfig.getBool(widget.remoteKey),
            nameIdAds: widget.adsKey,
            height: double.infinity,
            adUnitId: CallApi.instance.getFirstIDByName(widget.adsKey),
            factoryId: 'native_after_inter',
            onAdFailed: (p0) {

            },
          ),
        ],
      ),
    );
  }
}
