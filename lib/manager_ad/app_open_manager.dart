import 'dart:async';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../amazic_ads_flutter_platform_interface.dart';
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

    EventLog.logEvent('app_open_splash_true');

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

  //ad preloading
  Future<void> loadAppOpenAdPreload({
    required String idAds,
    required bool config,
    required Function()? onAdLoaded,
    required Function()? onAdFailedToLoad,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
      print('admob_ads --- App Open Ad Preload: can not load');
      onAdFailedToLoad?.call();
      return;
    }

    final adsPlatform = AmazicAdsFlutterPlatform.instance;
    adsPlatform.onAdLoaded = (id) {
      print('admob_ads --- App Open Ad Preload: onAdLoaded');
      onAdLoaded?.call();
    };
    adsPlatform.onAdFailedToLoad = (id, error) {
      print('admob_ads --- App Open Ad Preload: onAdFailedToLoad');
      onAdFailedToLoad?.call();
    };

    adsPlatform.loadAppOpenAdPreload(idAds, Admob.instance.numberPreload);
  }

  Future<void> showAppOpenAdPreload({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    required Function() onNext,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function()? onAdFailedToShow,
    Function()? onAdDismiss,
    required String name,
    bool isShowLoading = true,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
      print('admob_ads --- App Open Ad Preload: can not load');
      onNext.call();
      return;
    }

    print('admob_ads --- App Open Ad Preload: start show');
    if (navigatorKey.currentContext != null && isShowLoading) {
      print('admob_ads --- App Open Ad Preload: show dialog loading');
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    final adsPlatform = AmazicAdsFlutterPlatform.instance;

    adsPlatform.onAdClicked = () {
      onAdClicked?.call();
    };
    adsPlatform.onAdDismissed = () {
      print('admob_ads --- App Open Ad Preload: onAdDismissed');
      if (navigatorKey.currentContext != null && isShowLoading) {
        print('admob_ads --- Inter Ad Preload: onAdDismissed - close dialog loading');
        closeLoadingDialog(context: navigatorKey.currentContext!);
      }

      Admob.instance.setFullScreenAdShowing(false);
      onAdDismiss?.call();
      onNext.call();
    };
    adsPlatform.onAdFailedToShow = (id, error) {
      print('admob_ads --- App Open Ad Preload: onAdFailedToShow');

      if (navigatorKey.currentContext != null && isShowLoading) {
        print('admob_ads --- App Open Ad Preload: onAdFailedToShow - close dialog loading');
        closeLoadingDialog(context: navigatorKey.currentContext!);
      }
      Admob.instance.setFullScreenAdShowing(false);
      onAdFailedToShow?.call();
      onNext();
    };
    adsPlatform.onAdImpression = () {
      print('admob_ads --- App Open Ad Preload: onAdImpression');

      Admob.instance.setFullScreenAdShowing(true);

      onAdImpression?.call();
      EventLog.logEvent('${name}_view');
    };
    adsPlatform.onPaidEvent = (network, valueMicros, currency) {
      AdjustUtil.instance.trackRevenue(network: network, revenue: valueMicros, currency: currency);
    };

    Admob.instance.setFullScreenAdShowing(true);
    Admob.instance.checkAndShowAdForeground(
      onShow: () {
        print('admob_ads --- App Open Ad Preload: show Ads');
        adsPlatform.showAppOpenAdPreload(idAds);
      },
    );
  }

  Future<void> loadAndShowAppOpenAdPreload({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    required Function() onNext,
    Function()? onAdLoaded,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function()? onAdFailedToLoad,
    Function()? onAdFailedToShow,
    Function()? onAdDismiss,
    required String name,
  }) async {
    if (await AmazicAdsFlutterPlatform.instance.isAdAvailableAppOpen(idAds) == true) {
      print('admob_ads --- App Open Ad Preload - loadAndShow: HAVE DATA -> Show Ads');
      showAppOpenAdPreload(
        navigatorKey: navigatorKey,
        idAds: idAds,
        config: config,
        onNext: onNext,
        onAdImpression: onAdImpression,
        onAdClicked: onAdClicked,
        onAdFailedToShow: onAdFailedToShow,
        onAdDismiss: onAdDismiss,
        name: name,
      );
    } else {
      print('admob_ads --- App Open Ad Preload - loadAndShow: NOT HAVE DATA -> Loand And Show Ads');

      if (config == false ||
          ConsentManager.instance.canRequestAds == false ||
          Admob.instance.isShowAllAds == false ||
          (await Admob.instance.isNetworkActive()) == false) {
        print('admob_ads --- App Open Ad Preload - loadAndShow: not load');
        onNext.call();
        return;
      }

      if (navigatorKey.currentContext != null) {
        showLoadingDialog(context: navigatorKey.currentContext!);
      }

      bool isFirstLoadAd = true;
      final adsPlatform = AmazicAdsFlutterPlatform.instance;
      adsPlatform.onAdLoaded = (id) {
        print('admob_ads --- App Open Ad Preload - loadAndShow: onAdLoaded');
        if (isFirstLoadAd) {
          isFirstLoadAd = false;
          onAdLoaded?.call();
          showAppOpenAdPreload(
            navigatorKey: navigatorKey,
            idAds: idAds,
            config: config,
            onNext: onNext,
            name: name,
            onAdImpression: () {
              Admob.instance.setFullScreenAdShowing(true);
              onAdImpression?.call();
              EventLog.logEvent('${name}_view');
            },
            onAdClicked: onAdClicked,
            onAdFailedToShow: () {
              print(
                'admob_ads --- App Open Ad Preload - loadAndShow: onAdFailedToShowFullScreenContent',
              );
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              Admob.instance.setFullScreenAdShowing(false);
              onAdFailedToShow?.call();
            },
            onAdDismiss: () {
              print(
                'admob_ads --- App Open Ad Preload - loadAndShow: onAdDismissedFullScreenContent',
              );
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              Admob.instance.setFullScreenAdShowing(false);
              onAdDismiss?.call();
            },
            isShowLoading: false,
          );
        }
      };
      adsPlatform.onAdFailedToLoad = (id, error) {
        print('admob_ads --- App Open Ad Preload - loadAndShow: onAdFailedToLoad');
        onAdFailedToLoad?.call();
        onNext();
      };

      adsPlatform.loadAppOpenAdPreload(idAds, Admob.instance.numberPreload);
    }
  }

  Future<void> loadAndShowAppOpenSplashAdPreload({
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
        print('admob_ads --- App Open Ad preload: Timeout 20s - cancel show ads splash');
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
        print('admob_ads --- App Open Ad preload: open splash đã show Xong hoặc bị False');
        if (!timeoutCompleter.isCompleted) timeoutCompleter.complete();
      }
    }

    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
      print('admob_ads --- App Open Ad preload: not load');
      handleAdShown();
      onAdDisable?.call();
      return;
    }

    print('admob_ads --- App Open Ad preload: start request');
    if (navigatorKey.currentContext != null) {
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    EventLog.logEvent('app_open_splash_true');

    final adsPlatform = AmazicAdsFlutterPlatform.instance;
    adsPlatform.onAdLoaded = (id) {
      print('admob_ads --- App Open Ad preload: onAdLoaded');
      onAdLoaded?.call();

      if (!isNextTimeoutAd) {
        showAppOpenSplashApPreload(
          navigatorKey: navigatorKey,
          idAds: idAds,
          onAdImpression: () {
            handleAdShown();
            onAdImpression?.call();
          },
          onAdClicked: onAdClicked,
          onAdFailedToShow: onAdFailedToShow,
          onAdDismiss: onAdDismiss,
        );
      }
    };
    adsPlatform.onAdFailedToLoad = (id, error) {
      print('admob_ads --- App Open Ad preload: onAdFailedToLoad');
      Admob.instance.setFullScreenAdShowing(false);
      handleAdShown();
      onAdFailedToLoad?.call();
      if (navigatorKey.currentContext != null) {
        closeLoadingDialog(context: navigatorKey.currentContext!);
      }
    };

    adsPlatform.loadAppOpenAdPreload(idAds, Admob.instance.numberPreloadSplash);
    print('admob_ads --- App Open Ad preload: đợi timeout xem đã Xong hay được Huỷ chưa');
    await timeoutCompleter.future;
    print('admob_ads --- App Open Ad preload: timeout ads splash đã Xong tiếp tục xử lý');
  }

  Future<void> showAppOpenSplashApPreload({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required Function()? onAdImpression,
    required Function()? onAdClicked,
    required Function()? onAdFailedToShow,
    required Function()? onAdDismiss,
  }) async {
    final adsPlatform = AmazicAdsFlutterPlatform.instance;

    adsPlatform.onAdClicked = () {
      onAdClicked?.call();
    };
    adsPlatform.onAdDismissed = () {
      print('admob_ads --- App Open Ad preload: onAdDismissed');
      if (navigatorKey.currentContext != null) {
        closeLoadingDialog(context: navigatorKey.currentContext!);
      }
      Admob.instance.setFullScreenAdShowing(false);
      onAdDismiss?.call();
    };
    adsPlatform.onAdFailedToShow = (id, error) {
      print('admob_ads --- App Open Ad preload: onAdFailedToShow');

      if (navigatorKey.currentContext != null) {
        closeLoadingDialog(context: navigatorKey.currentContext!);
      }
      Admob.instance.setFullScreenAdShowing(false);
      onAdFailedToShow?.call();
    };
    adsPlatform.onAdImpression = () {
      print('admob_ads --- App Open Ad preload: onAdImpression');
      adsPlatform.destroyAppOpenAdPreload(idAds);

      Admob.instance.setFullScreenAdShowing(true);
      onAdImpression?.call();
    };
    adsPlatform.onPaidEvent = (network, valueMicros, currency) {
      AdjustUtil.instance.trackRevenue(network: network, revenue: valueMicros, currency: currency);
    };
    Admob.instance.setFullScreenAdShowing(true);
    Admob.instance.checkAndShowAdForeground(
      onShow: () {
        print('admob_ads --- App Open Ad preload: show Ads');
        adsPlatform.showAppOpenAdPreload(idAds);
      },
    );
  }
}
