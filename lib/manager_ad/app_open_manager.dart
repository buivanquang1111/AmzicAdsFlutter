import 'dart:async';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ump/consent_manager.dart';
import '../utils/adjust_util.dart';
import '../utils/event_log.dart';
import '../utils/utils.dart';

class AppOpenManager {
  AppOpenManager._instance();

  static final AppOpenManager instance = AppOpenManager._instance();

  ///value app open splash
  AppOpenAd? _mAppOpenAdSplash = null;

  setAppOpenAdSplash(AppOpenAd value) => _mAppOpenAdSplash = value;

  AppOpenAd? get mAppOpenAdSplash => _mAppOpenAdSplash;

  ///biến check xem đã chuyển màn trong timeout Ads chua
  bool isNextTimeoutAd = false;

  ///preload app open splash
  Future<void> loadAndShowAppOpenSplash({
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
  }) async {
    ///timeout check 12s
    bool adHasShown = false;
    final timeoutCompleter = Completer<void>(); //kiểm soát timeout 12s

    Future.delayed(const Duration(seconds: 20), () {
      if (!adHasShown) {
        print('admob_ads --- app_open_ads_splash: Timeout 20s - cancel show ads splash');
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

    void handleAdShown() {
      if (!adHasShown) {
        adHasShown = true;
        print('admob_ads --- app_open_ads_splash: open splash đã show Xong hoặc bị False');
        if (!timeoutCompleter.isCompleted) timeoutCompleter.complete();
      }
    }

    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
      print('admob_ads --- app_open_ads_splash: not load');
      handleAdShown();
      onAdDisable?.call();
      return;
    }

    print('admob_ads --- app_open_ads_splash: start request');
    if (navigatorKey.currentContext != null) {
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    EventLog.logEvent('inter_splash_true');

    AppOpenAd.load(
      adUnitId: idAds,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print('admob_ads --- app_open_ads_splash: onAdLoaded');
          onAdLoaded?.call();

          setAppOpenAdSplash(ad);

          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            print('admob_ads --- app_open_ads_splash: onPaidEvent');
            AdjustUtil.instance.trackRevenue(
              network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
              revenue: valueMicros,
              currency: currencyCode,
            );
          };

          if (!isNextTimeoutAd) {
            showAppOpenAdsSplash(
              navigatorKey: navigatorKey,
              onAdImpression: () {
                handleAdShown();
                onAdImpression?.call();
              },
              onAdClicked: onAdClicked,
              onAdFailedToShow: onAdFailedToShow,
              onAdDismiss: onAdDismiss,
            );
          }
        },
        onAdFailedToLoad: (error) {
          print('admob_ads --- app_open_ads_splash: onAdFailedToLoad $error');
          Admob.instance.setFullScreenAdShowing(false);
          handleAdShown();
          onAdFailedToLoad?.call();
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }
        },
      ),
    );
    print('admob_ads --- app_open_ads_splash: đợi timeout xem đã Xong hay được Huỷ chưa');
    await timeoutCompleter.future;
    print('admob_ads --- app_open_ads_splash: timeout ads splash đã Xong tiếp tục xử lý');
  }

  Future<void> showAppOpenAdsSplash({
    required GlobalKey<NavigatorState> navigatorKey,
    required Function()? onAdImpression,
    required Function()? onAdClicked,
    required Function()? onAdFailedToShow,
    required Function()? onAdDismiss,
  }) async {
    if (_mAppOpenAdSplash == null) {
      print('admob_ads --- app_open_ads_splash: not show ad = null');
      if (navigatorKey.currentContext != null) {
        closeLoadingDialog(context: navigatorKey.currentContext!);
      }
      Admob.instance.setFullScreenAdShowing(false);
      onAdDismiss?.call();
      return;
    }

    _mAppOpenAdSplash?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('admob_ads --- app_open_ads_splash: onAdShowedFullScreenContent');
      },
      onAdImpression: (ad) {
        print('admob_ads --- app_open_ads_splash: onAdImpression');
        Admob.instance.setFullScreenAdShowing(true);
        _mAppOpenAdSplash = null;
        onAdImpression?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('admob_ads --- app_open_ads_splash: onAdFailedToShowFullScreenContent $error');
        if (navigatorKey.currentContext != null) {
          closeLoadingDialog(context: navigatorKey.currentContext!);
        }
        Admob.instance.setFullScreenAdShowing(false);
        ad.dispose();
        onAdFailedToShow?.call();
      },
      onAdDismissedFullScreenContent: (ad) {
        print('admob_ads --- app_open_ads_splash: onAdDismissedFullScreenContent');
        if (navigatorKey.currentContext != null) {
          closeLoadingDialog(context: navigatorKey.currentContext!);
        }
        Admob.instance.setFullScreenAdShowing(false);
        ad.dispose();
        onAdDismiss?.call();
      },
      onAdClicked: (ad) {
        print('admob_ads --- app_open_ads_splash: onAdClicked');
        onAdClicked?.call();
      },
    );

    Admob.instance.setFullScreenAdShowing(true);
    Admob.instance.checkAndShowAdForeground(
      onShow: () {
        print('admob_ads --- app_open_ads_splash: show');
        _mAppOpenAdSplash?.show();
      },
    );
  }

  ///load and show app open
  Future<void> loadAndShowAppOpenAds({
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

          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            print('admob_ads --- app_open_ads: onPaidEvent');
            AdjustUtil.instance.trackRevenue(
              network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
              revenue: valueMicros,
              currency: currencyCode,
            );
          };

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('admob_ads --- app_open_ads: onAdShowedFullScreenContent');
            },
            onAdImpression: (ad) {
              print('admob_ads --- app_open_ads: onAdImpression');
              Admob.instance.setFullScreenAdShowing(true);
              onAdImpression?.call();
              EventLog.logEvent('${name}_view');
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('admob_ads --- app_open_ads: onAdFailedToShowFullScreenContent');
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              Admob.instance.setFullScreenAdShowing(false);
              ad.dispose();
              onAdFailedToShow?.call();
            },
            onAdDismissedFullScreenContent: (ad) {
              print('admob_ads --- app_open_ads: onAdDismissedFullScreenContent');
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              Admob.instance.setFullScreenAdShowing(false);
              ad.dispose();
              onAdDismiss?.call();
            },
            onAdClicked: (ad) {
              print('admob_ads --- app_open_ads: onAdClicked');
              onAdClicked?.call();
              EventLog.logEvent('${name}_view');
            },
          );

          Admob.instance.setFullScreenAdShowing(true);
          Admob.instance.checkAndShowAdForeground(
            onShow: () {
              print('admob_ads --- app_open_ads: show');
              ad.show();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('admob_ads --- app_open_ads: onAdFailedToLoad');
          Admob.instance.setFullScreenAdShowing(false);
          onAdFailedToLoad?.call();
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }
        },
      ),
    );
  }
}
