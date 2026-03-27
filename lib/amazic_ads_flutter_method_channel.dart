import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'amazic_ads_flutter_platform_interface.dart';

/// An implementation of [AmazicAdsFlutterPlatform] that uses method channels.
class MethodChannelAmazicAdsFlutter extends AmazicAdsFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('amazic_ads_flutter');

  //callback
  Function(String id)? _onAdLoaded;
  Function(String id, String error)? _onAdFailedToLoad;
  Function()? _onAdClicked;
  Function()? _onAdDismissed;
  Function(String id, String error)? _onAdFailedToShow;
  Function()? _onAdImpression;
  Function()? _onAdShowed;
  Function(String network, double revenue, String currency)? _onPainEvent;

  MethodChannelAmazicAdsFlutter() {
    methodChannel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'onAdLoaded':
          final String id = call.arguments;
          _onAdLoaded?.call(id);
          break;
        case 'onAdFailedToLoad':
          final String id = call.arguments['id'];
          final String error = call.arguments['error'];
          _onAdFailedToLoad?.call(id, error);
          break;
        case 'onAdClicked':
          _onAdClicked?.call();
          break;
        case 'onAdDismissed':
          _onAdDismissed?.call();
          break;
        case 'onAdFailedToShow':
          final String id = call.arguments['id'];
          final String error = call.arguments['error'];
          _onAdFailedToShow?.call(id, error);
          break;
        case 'onAdImpression':
          _onAdImpression?.call();
          break;
        case 'onAdShowed':
          _onAdShowed?.call();
          break;
        case 'onPaidEvent':
          final String network = call.arguments['network'];
          final double valueMicros = call.arguments['valueMicros'];
          final String currencyCode = call.arguments['currencyCode'];

          _onPainEvent?.call(network, valueMicros, currencyCode);
          break;
        default:
          throw UnimplementedError('Unimplemented ${call.method} method');
      }
    });
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool?> getConsentResult() async {
    return await methodChannel.invokeMethod<bool?>('hasConsentPurposeOne');
  }

  @override
  Future<bool?> isNetworkActive() async {
    return await methodChannel.invokeMethod<bool?>('isNetworkActive');
  }

  @override
  Future<void> loadInterAdPreload(String idAds, int numberPreload) async {
    await methodChannel.invokeMethod<void>('loadInterAdPreload', {
      'idAds': idAds,
      'numberPreload': numberPreload,
    });
  }

  @override
  Future<void> showInterAdPreload(String idAds) async {
    await methodChannel.invokeMethod<void>('showInterAdPreload', {'idAds': idAds});
  }

  @override
  Future<void> destroyInterAdPreload(String idAds) async {
    await methodChannel.invokeMethod<void>('destroyInterAdPreload', {'idAds': idAds});
  }

  @override
  set onAdLoaded(Function(String id)? callback) => _onAdLoaded = callback;

  @override
  set onAdFailedToLoad(Function(String id, String error)? callback) => _onAdFailedToLoad = callback;

  @override
  set onAdClicked(Function()? callback) => _onAdClicked = callback;

  @override
  set onAdDismissed(Function()? callback) => _onAdDismissed = callback;

  @override
  set onAdFailedToShow(Function(String id, String error)? callback) => _onAdFailedToShow = callback;

  @override
  set onAdImpression(Function()? callback) => _onAdImpression = callback;

  @override
  set onAdShowed(Function()? callback) => _onAdShowed = callback;

  @override
  set onPaidEvent(Function(String network, double valueMicros, String currency)? callback)  => _onPainEvent = callback;
}
