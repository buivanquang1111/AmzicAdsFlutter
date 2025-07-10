import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:amazic_ads_flutter/utils/ad_foreground_observer.dart';
import 'package:amazic_ads_flutter/utils/ad_helper.dart';
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
    required String idAdsResume,
    required bool isShowWelComeScreenAfterAppOpenAds,
    Function()? onGotoScreenWelcomeBack,
    required String idAdsAppOpenSplash,
    required String idAdsInterSplash,
    required bool configAppOpenSplash,
    required bool configInterSplash,
    required String rateAoa,
    required Function() onNext,
    required int intervalBetweenInter,
    required int intervalFromStart,
  }) async {
    //init UMP
    ConsentManager.instance.handleRequestUmp(
      onPostExecute: () {
        if(ConsentManager.instance.canRequestAds) {
          ///init app open resume
          appLifecycleReactor = AppLifecycleReactor(
            navigatorKey: navigatorKey,
            idAds: idAdsResume,
            config: true,
            isShowWelComeScreenAfterAppOpenAds: isShowWelComeScreenAfterAppOpenAds,
            onGotoWelcomeBack: onGotoScreenWelcomeBack,
          );
          appLifecycleReactor?.listenToAppStateChanges();

          ///init ads splash
          AdHelper.init(
              intervalBetweenInter: intervalBetweenInter * 1000,
              intervalFromStart: intervalFromStart * 1000,
              configAppOpen: configAppOpenSplash,
              configInter: configInterSplash,
              rateAoa: rateAoa
          );
          initAndShowAdSplash(
            navigatorKey: navigatorKey,
            idAdsAppOpen: idAdsAppOpenSplash,
            idAdsInter: idAdsInterSplash,
            configAppOpen: configAppOpenSplash,
            configInter: configInterSplash,
            onNext: onNext,
          );
        }else{
          onNext();
        }
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

  ///dung de check show inter/app open/reward
  checkAndShowAdForeground({required Function() onShow}) {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      onShow();
    } else {
      final observer = AdForegroundObserver(onShow: onShow);
      observer.attach();
    }
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
      print('admob_ads --- inter_ads: not load');
      onAdDisable?.call();
      return;
    }
    print('admob_ads --- inter_ads: start request');
    if (navigatorKey.currentContext != null) {
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    InterstitialAd.load(
      adUnitId: idAds,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('admob_ads --- inter_ads: onAdLoaded');
          onAdLoaded?.call();

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('admob_ads --- inter_ads: onAdShowedFullScreenContent');
            },
            onAdImpression: (ad) {
              print('admob_ads --- inter_ads: onAdImpression');
              setFullScreenAdShowing(true);
              onAdImpression?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('admob_ads --- inter_ads: onAdFailedToShowFullScreenContent');
              setFullScreenAdShowing(false);
              ad.dispose();
              onAdFailedToShow?.call();
            },
            onAdDismissedFullScreenContent: (ad) {
              print('admob_ads --- inter_ads: onAdDismissedFullScreenContent');
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              setFullScreenAdShowing(false);
              AdHelper.setLastTimeDismissInter();
              ad.dispose();
              onAdDismiss?.call();
            },
            onAdClicked: (ad) {
              print('admob_ads --- inter_ads: onAdClicked');
              onAdClicked?.call();
            },
          );
          setFullScreenAdShowing(true);
          checkAndShowAdForeground(
            onShow: () {
              print('admob_ads --- inter_ads: show');
              ad.show();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('admob_ads --- inter_ads: onAdFailedToLoad');
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

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('reward_ads: onAdShowedFullScreenContent');
            },
            onAdImpression: (ad) {
              print('reward_ads: onAdImpression');
              setFullScreenAdShowing(true);
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
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              setFullScreenAdShowing(false);
              ad.dispose();
              onAdDismiss?.call();
            },
            onAdClicked: (ad) {
              print('reward_ads: onAdClicked');
              onAdClicked?.call();
            },
          );
          setFullScreenAdShowing(true);
          checkAndShowAdForeground(
            onShow: () {
              print('reward_ads: show');
              ad.show(
                onUserEarnedReward: (ad, reward) {
                  print('reward_ads: onUserEarnedReward');
                  onUSerEarnedReward?.call();
                },
              );
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
      print('admob_ads --- app_open_ads: not load');
      onAdDisable?.call();
      return;
    }

    print('admob_ads --- app_open_ads: start request');
    if (navigatorKey.currentContext != null) {
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    AppOpenAd.load(
      adUnitId: idAds,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print('admob_ads --- app_open_ads: onAdLoaded');
          onAdLoaded?.call();

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('admob_ads --- app_open_ads: onAdShowedFullScreenContent');
            },
            onAdImpression: (ad) {
              print('admob_ads --- app_open_ads: onAdImpression');
              setFullScreenAdShowing(true);
              onAdImpression?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('admob_ads --- app_open_ads: onAdFailedToShowFullScreenContent');
              setFullScreenAdShowing(false);
              ad.dispose();
              onAdFailedToShow?.call();
            },
            onAdDismissedFullScreenContent: (ad) {
              print('admob_ads --- app_open_ads: onAdDismissedFullScreenContent');
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              setFullScreenAdShowing(false);
              ad.dispose();
              onAdDismiss?.call();
            },
            onAdClicked: (ad) {
              print('admob_ads --- app_open_ads: onAdClicked');
              onAdClicked?.call();
            },
          );

          setFullScreenAdShowing(true);
          checkAndShowAdForeground(
            onShow: () {
              print('admob_ads --- app_open_ads: show');
              ad.show();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('admob_ads --- app_open_ads: onAdFailedToLoad');
          setFullScreenAdShowing(false);
          onAdFailedToLoad?.call();
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }
        },
      ),
    );
  }

  Future<void> initAndShowAdSplash({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAdsAppOpen,
    required String idAdsInter,
    required bool configAppOpen,
    required bool configInter,
    required Function() onNext,
  }) async {
    if (AdHelper.splashType == AdsSplashType.open) {
      loadAndShowAppOpenAds(
        navigatorKey: navigatorKey,
        idAds: idAdsAppOpen,
        config: configAppOpen,
        onAdDisable: () {
          Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
          onNext();
        },
        onAdFailedToShow: () {
          Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
          onNext();
        },
        onAdFailedToLoad: () {
          Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
          onNext();
        },
        onAdDismiss: () {
          Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
          onNext();
        },
        onAdClicked: () {},
        onAdImpression: () {},
        onAdLoaded: () {},
      );
    } else if (AdHelper.splashType == AdsSplashType.inter) {
      loadAndShowInterAds(
        navigatorKey: navigatorKey,
        idAds: idAdsInter,
        config: configInter,
        onAdLoaded: () {},
        onAdImpression: () {},
        onAdClicked: () {},
        onAdDismiss: () {
          Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
          onNext();
        },
        onAdFailedToLoad: () {
          Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
          onNext();
        },
        onAdFailedToShow: () {
          Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
          onNext();
        },
        onAdDisable: () {
          Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
          onNext();
        },
      );
    } else {
      Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
      onNext();
    }
  }
}
