import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'amazic_ads_flutter_method_channel.dart';

abstract class AmazicAdsFlutterPlatform extends PlatformInterface {
  /// Constructs a AmazicAdsFlutterPlatform.
  AmazicAdsFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static AmazicAdsFlutterPlatform _instance = MethodChannelAmazicAdsFlutter();

  /// The default instance of [AmazicAdsFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelAmazicAdsFlutter].
  static AmazicAdsFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AmazicAdsFlutterPlatform] when
  /// they register themselves.
  static set instance(AmazicAdsFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  //setter for callback
  set onAdLoaded(Function(String id)? callback) => throw UnimplementedError();
  set onAdFailedToLoad(Function(String id, String error)? callback) => throw UnimplementedError();
  set onAdClicked(Function()? callback) => throw UnimplementedError();
  set onAdDismissed(Function()? callback) => throw UnimplementedError();
  set onAdFailedToShow(Function(String id, String error)? callback) => throw UnimplementedError();
  set onAdImpression(Function()? callback) => throw UnimplementedError();
  set onAdShowed(Function()? callback) => throw UnimplementedError();
  set onPaidEvent(Function(String network, double valueMicros, String currency)? callback) => throw UnimplementedError();

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool?> getConsentResult() {
    throw UnimplementedError('getConsentResult() has not been implemented.');
  }

  Future<bool?> isNetworkActive() {
    throw UnimplementedError('isNetworkActive() has not been implemented.');
  }

  Future<void> loadInterAdPreload(String idAds, int numberPreload){
    throw UnimplementedError('loadInterAdPreload() has not been implemented.');
  }

  Future<void> showInterAdPreload(String idAds){
    throw UnimplementedError('showInterAdPreload() has not been implemented.');
  }

  Future<void> destroyInterAdPreload(String idAds){
    throw UnimplementedError('destroyInterAdPreload() has not been implemented.');
  }

}
