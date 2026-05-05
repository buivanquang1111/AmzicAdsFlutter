import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'amazic_ads_flutter_platform_interface.dart';

/// An implementation of [AmazicAdsFlutterPlatform] that uses method channels.
class MethodChannelAmazicAdsFlutter extends AmazicAdsFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('amazic_ads_flutter');

  final interChannel = const MethodChannel("amazic_ads_inter");
  final appOpenChannel = const MethodChannel("amazic_ads_app_open");
  final rewardChannel = const MethodChannel("amazic_ads_reward");
  final nativeAfterInterChannel = const MethodChannel("amazic_ads_native_after_inter");

  //callback
  Function(String id)? _onAdLoaded;
  Function(String id, String error)? _onAdFailedToLoad;
  Function()? _onAdClicked;
  Function()? _onAdDismissed;
  Function(String id, String error)? _onAdFailedToShow;
  Function()? _onAdImpression;
  Function()? _onAdShowed;
  Function(String network, double revenue, String currency)? _onPaidEvent;
  Function()? _onUserEarnedReward;
  Function()? _onNativeAfterInterClose;

  MethodChannelAmazicAdsFlutter() {
    interChannel.setMethodCallHandler((call) async {
      _processCallback(call, "INTER_ADS");
    });

    appOpenChannel.setMethodCallHandler((call) async {
      _processCallback(call, "APP_OPEN_ADS");
    });

    rewardChannel.setMethodCallHandler((call) async {
      _processCallback(call, "REWARD_ADS");
    });

    nativeAfterInterChannel.setMethodCallHandler((call) async {
      _processCallback(call, "NATIVE_AFTER_INTER");
    });
  }

  void _processCallback(MethodCall call, String logSource) {
    final Map<dynamic, dynamic> args = call.arguments is Map ? call.arguments : {};
    final String id = args['id'] ?? "";

    print("[$logSource] Method: ${call.method} | ID: $id");

    switch (call.method) {
      case 'onAdLoaded':
        _onAdLoaded?.call(id);
        break;
      case 'onAdFailedToLoad':
        _onAdFailedToLoad?.call(id, args['error'] ?? "Unknown Error");
        break;
      case 'onAdClicked':
        _onAdClicked?.call();
        break;
      case 'onAdDismissed':
        _onAdDismissed?.call();
        break;
      case 'onAdFailedToShow':
        _onAdFailedToShow?.call(id, args['error'] ?? "Unknown Error");
        break;
      case 'onAdImpression':
        _onAdImpression?.call();
        break;
      case 'onAdShowed':
        _onAdShowed?.call();
        break;
      case 'onPaidEvent':
        final String network = args['network'].toString() ?? "";
        final double valueMicros = (args['valueMicros'] as num?)?.toDouble() ?? 0.0;
        final String currencyCode = args['currencyCode'].toString() ?? "";
        print("[$logSource] Method: ${call.method} | ID: $id | network: $network | valueMicros: $valueMicros | currencyCode: $currencyCode");
        _onPaidEvent?.call(network, valueMicros, currencyCode);
        break;
      case 'onUserEarned':
        _onUserEarnedReward?.call();
        break;
      case 'onNativeAfterInterClose':
        _onNativeAfterInterClose?.call();
        break;
      default:
        throw UnimplementedError('Unimplemented ${call.method} method');
    }
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
  Future<bool?> isAdAvailableInter(String idAds) async {
    return await interChannel.invokeMethod<bool?>('isAdAvailableInter', {'idAds': idAds});
  }

  @override
  Future<void> loadInterAdPreload(String idAds, int numberPreload) async {
    await interChannel.invokeMethod<void>('loadInterAdPreload', {
      'idAds': idAds,
      'numberPreload': numberPreload,
    });
  }

  @override
  Future<void> showInterAdPreload(String idAds) async {
    await interChannel.invokeMethod<void>('showInterAdPreload', {'idAds': idAds});
  }

  @override
  Future<void> destroyInterAdPreload(String idAds) async {
    await interChannel.invokeMethod<void>('destroyInterAdPreload', {'idAds': idAds});
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
  set onPaidEvent(Function(String network, double valueMicros, String currency)? callback) =>
      _onPaidEvent = callback;

  @override
  set onUserEarnedReward(Function()? callback) => _onUserEarnedReward = callback;

  @override
  set onNativeAfterInterClose(Function()? callback) => _onNativeAfterInterClose = callback;

  @override
  Future<void> loadAppOpenAdPreload(String idAds, int numberPreload) async {
    await appOpenChannel.invokeMethod<void>('loadAppOpenAdPreload', {
      'idAds': idAds,
      'numberPreload': numberPreload,
    });
  }

  @override
  Future<void> showAppOpenAdPreload(String idAds) async {
    await appOpenChannel.invokeMethod<void>('showAppOpenAdPreload', {'idAds': idAds});
  }

  @override
  Future<bool?> isAdAvailableAppOpen(String idAds) async {
    return await appOpenChannel.invokeMethod<bool?>('isAdAvailableAppOpen', {'idAds': idAds});
  }

  @override
  Future<void> destroyAppOpenAdPreload(String idAds) async {
    await appOpenChannel.invokeMethod<void>('destroyAppOpenAdPreload', {'idAds': idAds});
  }

  @override
  Future<void> loadRewardAdPreload(String idAds, int numberPreload) async {
    await rewardChannel.invokeMethod<void>('loadRewardAdPreload', {
      'idAds': idAds,
      'numberPreload': numberPreload,
    });
  }

  @override
  Future<void> showRewardAdPreload(String idAds) async {
    await rewardChannel.invokeMethod<void>('showRewardAdPreload', {'idAds': idAds});
  }

  @override
  Future<bool?> isAdAvailableReward(String idAds) async {
    return await rewardChannel.invokeMethod<bool?>('isAdAvailableReward', {'idAds': idAds});
  }

  @override
  Future<void> destroyRewardAdPreload(String idAds) async {
    await rewardChannel.invokeMethod<void>('destroyRewardAdPreload', {'idAds': idAds});
  }
}
