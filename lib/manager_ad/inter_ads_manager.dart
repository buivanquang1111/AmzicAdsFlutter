import 'dart:async';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/utils/event_log.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ump/consent_manager.dart';
import '../utils/ad_helper.dart';
import '../utils/adjust_util.dart';
import '../utils/utils.dart';

class InterAdsManager {
  InterAdsManager._instance();

  static final InterAdsManager instance = InterAdsManager._instance();

  ///value inter splash
  InterstitialAd? _mInterstitialAdSplash = null;

  setInterstitialAdSplash(InterstitialAd value) => _mInterstitialAdSplash = value;

  InterstitialAd? get mInterstitialAdSplash => _mInterstitialAdSplash;

  ///biến check xem đã chuyển màn trong timeout Ads chua
  bool isNextTimeoutAd = false;

  ///preload inter splash
  Future<void> loadAndShowInterSplash({
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
    ///timeout check 12s
    bool adHasShown = false;
    final timeoutCompleter = Completer<void>(); //kiểm soát timeout 12s

    Future.delayed(const Duration(seconds: 20), () {
      if (!adHasShown) {
        print('admob_ads --- inter_ads_splash: Timeout 20s - cancel show ads splash');
        EventLog.logEvent('inter_splash_id_timeout');
        Admob.instance.setFullScreenAdShowing(false);
        if (navigatorKey.currentContext != null) {
          closeLoadingDialog(context: navigatorKey.currentContext!);
        }
        timeoutCompleter.complete();
        isNextTimeoutAd = true;
        onAdDisable?.call();
      }
    });

    void handleAdsShown() {
      if (!adHasShown) {
        adHasShown = true;
        print('admob_ads --- inter_ads_splash: inter splash đã show Xong hoặc bị False');
        if (!timeoutCompleter.isCompleted) timeoutCompleter.complete();
      }
    }

    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
      print('admob_ads --- inter_ads_splash: not load');
      handleAdsShown();
      onAdDisable?.call();
      return;
    }
    print('admob_ads --- inter_ads_splash: start request');
    if (navigatorKey.currentContext != null) {
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    EventLog.logEvent('inter_splash_true');

    InterstitialAd.load(
      adUnitId: idAds,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('admob_ads --- inter_ads_splash: onAdLoaded');

          logInterMediation(ad: ad, nameAds: 'Inter splash');
          onAdLoaded?.call();

          setInterstitialAdSplash(ad);

          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            print('admob_ads --- inter_ads_splash: onPaidEvent');
            AdjustUtil.instance.trackRevenue(
              network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
              revenue: valueMicros,
              currency: currencyCode,
            );
          };

          if (!isNextTimeoutAd) {
            showInterAdsSplash(
              navigatorKey: navigatorKey,
              onAdImpression: () {
                handleAdsShown();
                onAdImpression?.call();
              },
              onAdClicked: onAdClicked,
              onAdFailedToShow: onAdFailedToShow,
              onAdDismiss: onAdDismiss,
            );
          }
        },
        onAdFailedToLoad: (error) {
          print('admob_ads --- inter_ads_splash: onAdFailedToLoad ${error.message}');
          Admob.instance.setFullScreenAdShowing(false);
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }
          handleAdsShown();
          onAdFailedToLoad?.call();
        },
      ),
    );

    print('admob_ads --- inter_ads_splash: đợi timeout xem đã xong hay được huỷ chưa');
    await timeoutCompleter.future;
    print('admob_ads --- inter_ads_splash: timeout ads splash đã xong tiếp tục xử lý');
  }

  Future<void> showInterAdsSplash({
    required GlobalKey<NavigatorState> navigatorKey,
    required Function()? onAdImpression,
    required Function()? onAdClicked,
    required Function()? onAdFailedToShow,
    required Function()? onAdDismiss,
  }) async {
    if (_mInterstitialAdSplash == null) {
      print('admob_ads --- inter_ads_splash: not show ad = null');
      if (navigatorKey.currentContext != null) {
        closeLoadingDialog(context: navigatorKey.currentContext!);
      }
      Admob.instance.setFullScreenAdShowing(false);
      onAdDismiss?.call();
      return;
    }

    _mInterstitialAdSplash?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('admob_ads --- inter_ads_splash: onAdShowedFullScreenContent');
      },
      onAdImpression: (ad) {
        print('admob_ads --- inter_ads_splash: onAdImpression');
        Admob.instance.setFullScreenAdShowing(true);
        _mInterstitialAdSplash = null;
        onAdImpression?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('admob_ads --- inter_ads_splash: onAdFailedToShowFullScreenContent $error');
        if (navigatorKey.currentContext != null) {
          closeLoadingDialog(context: navigatorKey.currentContext!);
        }
        Admob.instance.setFullScreenAdShowing(false);
        ad.dispose();
        onAdFailedToShow?.call();
      },
      onAdDismissedFullScreenContent: (ad) {
        print('admob_ads --- inter_ads_splash: onAdDismissedFullScreenContent');
        if (navigatorKey.currentContext != null) {
          closeLoadingDialog(context: navigatorKey.currentContext!);
        }
        Admob.instance.setFullScreenAdShowing(false);
        ad.dispose();
        onAdDismiss?.call();
      },
      onAdClicked: (ad) {
        print('admob_ads --- inter_ads_splash: onAdClicked');
        onAdClicked?.call();
      },
    );
    Admob.instance.setFullScreenAdShowing(true);
    Admob.instance.checkAndShowAdForeground(
      onShow: () {
        print('admob_ads --- inter_ads_splash: show');
        _mInterstitialAdSplash?.setImmersiveMode(true);
        _mInterstitialAdSplash?.show();
      },
    );
  }

  ///load and show
  Future<void> loadAndShowInterAds({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    required Function()? onAdDisable,
    required Function()? onAdLoaded,
    required Function()? onAdImpression,
    required Function()? onAdClicked,
    required Function()? onAdFailedToLoad,
    required Function()? onAdFailedToShow,
    required Function()? onAdDismiss,
    required String name,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
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

          logInterMediation(ad: ad, nameAds: name);

          onAdLoaded?.call();

          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            print('admob_ads --- inter_ads: onPaidEvent');
            AdjustUtil.instance.trackRevenue(
              network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
              revenue: valueMicros,
              currency: currencyCode,
            );
          };

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('admob_ads --- inter_ads: onAdShowedFullScreenContent');
            },
            onAdImpression: (ad) {
              print('admob_ads --- inter_ads: onAdImpression');
              Admob.instance.setFullScreenAdShowing(true);
              onAdImpression?.call();
              EventLog.logEvent('${name}_view');
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('admob_ads --- inter_ads: onAdFailedToShowFullScreenContent ${error.message}');
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              Admob.instance.setFullScreenAdShowing(false);
              ad.dispose();
              onAdFailedToShow?.call();
            },
            onAdDismissedFullScreenContent: (ad) {
              print('admob_ads --- inter_ads: onAdDismissedFullScreenContent');
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              Admob.instance.setFullScreenAdShowing(false);
              AdHelper.setLastTimeDismissInter();
              ad.dispose();
              onAdDismiss?.call();
            },
            onAdClicked: (ad) {
              print('admob_ads --- inter_ads: onAdClicked');
              onAdClicked?.call();
              EventLog.logEvent('${name}_click');
            },
          );
          Admob.instance.setFullScreenAdShowing(true);
          Admob.instance.checkAndShowAdForeground(
            onShow: () {
              print('admob_ads --- inter_ads: show');
              ad.setImmersiveMode(true);
              ad.show();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('admob_ads --- inter_ads: onAdFailedToLoad ${error.message}');
          Admob.instance.setFullScreenAdShowing(false);
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }
          onAdFailedToLoad?.call();
        },
      ),
    );
  }
}
