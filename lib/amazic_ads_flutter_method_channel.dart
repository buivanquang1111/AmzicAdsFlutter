import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'amazic_ads_flutter_platform_interface.dart';

/// An implementation of [AmazicAdsFlutterPlatform] that uses method channels.
class MethodChannelAmazicAdsFlutter extends AmazicAdsFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('amazic_ads_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool?> getConsentResult() async{
    return await methodChannel.invokeMethod<bool?>('hasConsentPurposeOne');
  }

  @override
  Future<bool?> isNetworkActive() async{
    return await methodChannel.invokeMethod<bool?>('isNetworkActive');
  }
}
