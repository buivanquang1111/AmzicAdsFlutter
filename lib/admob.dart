import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:amazic_ads_flutter/utils/app_lifecycle_reactor.dart';
import 'package:amazic_ads_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'amazic_ads_flutter_platform_interface.dart';

class Admob {
  Admob._Admob();

  static final Admob instance = Admob._Admob();

  GlobalKey<NavigatorState>? navigatorKey;

  ///enable show full ads
  bool _isShowAllAds = true;

  setShowAllAds(bool value) => _isShowAllAds = value;

  bool get isShowAllAds => _isShowAllAds;

  ///true when ads show full screen
  bool _isFullScreenAdShowing = false;

  setFullScreenAdShowing(bool value) => _isFullScreenAdShowing = value;

  bool get isFullScreenAdShowing => _isFullScreenAdShowing;

  ///ads app open
  AppLifecycleReactor? appLifecycleReactor;

  Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAdsAppOpen,
    required bool isShowWelComeScreenAfterAppOpenAds,
    Function()? onGotoScreenWelcomeBack,
  }) async {
    //init UMP
    ConsentManager.instance.handleRequestUmp(
      onPostExecute: () {
        appLifecycleReactor = AppLifecycleReactor(
          navigatorKey: navigatorKey,
          idAds: idAdsAppOpen,
          config: true,
          isShowWelComeScreenAfterAppOpenAds: isShowWelComeScreenAfterAppOpenAds,
          onGotoWelcomeBack: onGotoScreenWelcomeBack,
        );
        appLifecycleReactor?.listenToAppStateChanges();
      },
    );
  }

  Future<void> initAdmob() async {
    MobileAds.instance.initialize();
  }

  Future<String?> getPlatformVersion() {
    return AmazicAdsFlutterPlatform.instance.getPlatformVersion();
  }

  Future<bool?> getConsentResult() async {
    final canRequest = await AmazicAdsFlutterPlatform.instance.getConsentResult();
    print('ump: getConsentResult - $canRequest');
    return canRequest;
  }

  Future<bool?> isNetworkActive() async {
    final isConnected = await AmazicAdsFlutterPlatform.instance.isNetworkActive();
    print('have_internet: $isConnected');
    return isConnected;
  }

  Future<void> loadAndShowInterAds({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    Function()? onAdDisable,
    Function()? onAdLoaded,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function()? onAdFailedToLoad,
    Function()? onAdFailedToShow,
    Function()? onAdDismiss,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        isShowAllAds == false ||
        (await isNetworkActive()) == false) {
      print('inter_ads: not load');
      onAdDisable?.call();
      return;
    }
    print('inter_ads: start request');
    if (navigatorKey.currentContext != null) {
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    InterstitialAd.load(
      adUnitId: idAds,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('inter_ads: onAdLoaded');
          onAdLoaded?.call();
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('inter_ads: onAdShowedFullScreenContent');
            },
            onAdImpression: (ad) {
              print('inter_ads: onAdImpression');
              onAdImpression?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('inter_ads: onAdFailedToShowFullScreenContent');
              setFullScreenAdShowing(false);
              ad.dispose();
              onAdFailedToShow?.call();
            },
            onAdDismissedFullScreenContent: (ad) {
              print('inter_ads: onAdDismissedFullScreenContent');
              setFullScreenAdShowing(false);
              ad.dispose();
              onAdDismiss?.call();
            },
            onAdClicked: (ad) {
              print('inter_ads: onAdClicked');
              onAdClicked?.call();
            },
          );
          print('inter_ads: show');
          setFullScreenAdShowing(true);
          ad.show();
        },
        onAdFailedToLoad: (error) {
          print('inter_ads: onAdFailedToLoad');
          setFullScreenAdShowing(false);
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }
          onAdFailedToLoad?.call();
        },
      ),
    );
  }

  Future<void> loadAndShowRewardAds({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    Function()? onAdDisable,
    Function()? onAdLoaded,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function()? onAdFailedToLoad,
    Function()? onAdFailedToShow,
    Function()? onAdDismiss,
    Function()? onUSerEarnedReward,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        isShowAllAds == false ||
        (await isNetworkActive()) == false) {
      print('reward_ads: not load');
      onAdDisable?.call();
      return;
    }
    print('reward_ads: start request');
    if (navigatorKey.currentContext != null) {
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    RewardedAd.load(
      adUnitId: idAds,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('reward_ads: onAdLoaded');
          onAdLoaded?.call();
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('reward_ads: onAdShowedFullScreenContent');
            },
            onAdImpression: (ad) {
              print('reward_ads: onAdImpression');
              onAdImpression?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('reward_ads: onAdFailedToShowFullScreenContent');
              setFullScreenAdShowing(false);
              ad.dispose();
              onAdFailedToShow?.call();
            },
            onAdDismissedFullScreenContent: (ad) {
              print('reward_ads: onAdDismissedFullScreenContent');
              setFullScreenAdShowing(false);
              ad.dispose();
              onAdDismiss?.call();
            },
            onAdClicked: (ad) {
              print('reward_ads: onAdClicked');
              onAdClicked?.call();
            },
          );
          print('reward_ads: show');
          setFullScreenAdShowing(true);
          ad.show(
            onUserEarnedReward: (ad, reward) {
              print('reward_ads: onUserEarnedReward');
              onUSerEarnedReward?.call();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('reward_ads: onAdFailedToLoad');
          setFullScreenAdShowing(false);
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }
          onAdFailedToLoad?.call();
        },
      ),
    );
  }

  Future<void> loadAndShowAppOpenAds({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    Function()? onAdDisable,
    Function()? onAdLoaded,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function()? onAdFailedToLoad,
    Function()? onAdFailedToShow,
    Function()? onAdDismiss,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        isShowAllAds == false ||
        (await isNetworkActive()) == false) {
      print('app_open_ads: not load');
      onAdDisable?.call();
      return;
    }

    print('app_open_ads: start request');
    if (navigatorKey.currentContext != null) {
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    AppOpenAd.load(
      adUnitId: idAds,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print('app_open_ads: onAdLoaded');
          onAdLoaded?.call();
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('app_open_ads: onAdShowedFullScreenContent');
            },
            onAdImpression: (ad) {
              print('app_open_ads: onAdImpression');
              onAdImpression?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('app_open_ads: onAdFailedToShowFullScreenContent');
              setFullScreenAdShowing(false);
              ad.dispose();
              onAdFailedToShow?.call();
            },
            onAdDismissedFullScreenContent: (ad) {
              print('app_open_ads: onAdDismissedFullScreenContent');
              setFullScreenAdShowing(false);
              ad.dispose();
              onAdDismiss?.call();
            },
            onAdClicked: (ad) {
              print('app_open_ads: onAdClicked');
              onAdClicked?.call();
            },
          );

          print('app_open_ads: show');
          setFullScreenAdShowing(true);
          ad.show();
        },
        onAdFailedToLoad: (error) {
          print('app_open_ads: onAdFailedToLoad');
          setFullScreenAdShowing(false);
          onAdFailedToLoad?.call();
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }
        },
      ),
    );
  }
}
