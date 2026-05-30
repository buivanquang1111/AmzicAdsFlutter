import 'dart:async';
import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/amazic_ads_flutter_platform_interface.dart';
import 'package:amazic_ads_flutter/utils/event_log.dart';
import 'package:amazic_ads_flutter/utils/remote_config.dart';
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

  var isAdSplashFinished = false; //check show 1 ads splash => no fill => start next screen

  bool isTimeDelayNativeSplash = false;

  ///inter splash
  Future<void> loadAndShowInterSplash({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    Function()? onAdDisable,
    Function()? onAdLoaded,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function(String)? onAdFailedToLoad,
    Function(String)? onAdFailedToShow,
    Function()? onAdDismiss,
  }) async {
    ///timeout check 12s
    bool adHasShown = false;
    final timeoutCompleter = Completer<void>(); //kiểm soát timeout 12s
    DateTime startTime = DateTime.now();

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

    //timeout 7s native splash
    if (Admob.instance.isUseNativeSplash) {
      Admob.instance.logEventSplashToStep(nameEvent: 'splash_start_await_7s');
      print('admob_ads --- inter_ads_splash: start await 7s splash');
      Future.delayed(Duration(seconds: Admob.instance.timeDelayNativeSplash), () {
        Admob.instance.logEventSplashToStep(nameEvent: 'splash_done_await_7s');
        print('admob_ads --- inter_ads_splash: count done 7s');
        isTimeDelayNativeSplash = true;

        _checkConditionAdSplash(
          navigatorKey: navigatorKey,
          idAds: idAds,
          startTime: startTime,
          onAdImpression: () {
            handleAdsShown();
            onAdImpression?.call();
          },
          onAdClicked: onAdClicked,
          onAdFailedToShow: onAdFailedToShow,
          onAdDismiss: onAdDismiss,
        );
      });
    } else {
      print('admob_ads --- inter_ads_splash: do not use delay 7s');
      isTimeDelayNativeSplash = true;
    }

    var isNetwork = await Admob.instance.isNetworkActive();
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (isNetwork) == false) {
      print('admob_ads --- inter_ads_splash: not load');
      EventLog.logEvent(
        'inter_splash_config_${config}_${ConsentManager.instance.canRequestAds}_${Admob.instance.isShowAllAds}_$isNetwork',
      );
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
              adUnitId: idAds,
              adFormat: 'inter_splash',
            );
          };

          EventLog.logEvent(
            'inter_splash_check_show',
            parameters: {'message': 'isNextTimeoutAdSplash_${isNextTimeoutAd}'},
          );
          print('admob_ads --- inter_splash_check_show isNextTimeoutAdSplash_$isNextTimeoutAd');
          _checkConditionAdSplash(
            navigatorKey: navigatorKey,
            idAds: idAds,
            startTime: startTime,
            onAdImpression: () {
              handleAdsShown();
              onAdImpression?.call();
            },
            onAdClicked: onAdClicked,
            onAdFailedToShow: onAdFailedToShow,
            onAdDismiss: onAdDismiss,
          );
        },
        onAdFailedToLoad: (error) {
          print('admob_ads --- inter_ads_splash: onAdFailedToLoad ${error.message}');
          EventLog.logEvent('inter_splash_fail', parameters: {'error': error.message});
          Admob.instance.setFullScreenAdShowing(false);
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }
          handleAdsShown();
          onAdFailedToLoad?.call(error.message);
        },
      ),
    );

    print('admob_ads --- inter_ads_splash: đợi timeout xem đã xong hay được huỷ chưa');
    await timeoutCompleter.future;
    print('admob_ads --- inter_ads_splash: timeout ads splash đã xong tiếp tục xử lý');
  }

  void _checkConditionAdSplash({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required DateTime startTime,
    required Function()? onAdImpression,
    required Function()? onAdClicked,
    required Function(String)? onAdFailedToShow,
    required Function()? onAdDismiss,
  }) {
    if (isTimeDelayNativeSplash && !isNextTimeoutAd) {
      // Tính tổng thời gian đã chờ
      double totalWait = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      print("admob_ads --- ===> TỔNG THỜI GIAN CHỜ: $totalWait giây");

      showInterAdsSplash(
        navigatorKey: navigatorKey,
        onAdImpression: onAdImpression,
        onAdClicked: onAdClicked,
        onAdFailedToShow: onAdFailedToShow,
        onAdDismiss: onAdDismiss,
      );
    }
  }

  Future<void> showInterAdsSplash({
    required GlobalKey<NavigatorState> navigatorKey,
    required Function()? onAdImpression,
    required Function()? onAdClicked,
    required Function(String)? onAdFailedToShow,
    required Function()? onAdDismiss,
  }) async {
    if (_mInterstitialAdSplash == null) {
      print('admob_ads --- inter_ads_splash: not show ad = null');
      EventLog.logEvent(
        'inter_splash_show_fail',
        parameters: {"error": "mInterstitialAdSplash_null"},
      );
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
        EventLog.logEvent('inter_splash_view');
        Admob.instance.setFullScreenAdShowing(true);
        _mInterstitialAdSplash = null;
        onAdImpression?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('admob_ads --- inter_ads_splash: onAdFailedToShowFullScreenContent $error');
        EventLog.logEvent('inter_splash_fail', parameters: {'error': error.message});
        if (navigatorKey.currentContext != null) {
          closeLoadingDialog(context: navigatorKey.currentContext!);
        }
        Admob.instance.setFullScreenAdShowing(false);
        ad.dispose();
        onAdFailedToShow?.call(error.message);
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
    required Function(String)? onAdFailedToLoad,
    required Function(String)? onAdFailedToShow,
    required Function()? onAdDismiss,
    required String name,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
      print('admob_ads --- inter_ads: not load');
      EventLog.logEvent(
        '${name}_config_${config}_${ConsentManager.instance.canRequestAds}_${Admob.instance.isShowAllAds}',
      );
      onAdDisable?.call();
      return;
    }
    print('admob_ads --- inter_ads: start request');
    if (navigatorKey.currentContext != null) {
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    EventLog.logEvent('${name}_true');
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
              adUnitId: idAds,
              adFormat: name,
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
              EventLog.logEvent('${name}_fail', parameters: {'error': error.message});
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              Admob.instance.setFullScreenAdShowing(false);
              ad.dispose();
              onAdFailedToShow?.call(error.message);
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
          EventLog.logEvent('${name}_fail', parameters: {'error': error.message});
          Admob.instance.setFullScreenAdShowing(false);
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }
          onAdFailedToLoad?.call(error.message);
        },
      ),
    );
  }

  //ad preloading
  Future<void> loadInterAdPreload({
    required String idAds,
    required String nameConfig,
    required Function()? onAdLoaded,
    required Function(String)? onAdFailedToLoad,
  }) async {
    print('admob_ads --- Inter Ad Preload: loadInterAdPreload');
    var isNetwork = await Admob.instance.isNetworkActive();

    if (RemoteConfig.getBool(nameConfig) == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        isNetwork == false) {
      print('admob_ads --- Inter Ad Preload: can not load');
      EventLog.logEvent(
        '${nameConfig}_config_${RemoteConfig.getBool(nameConfig)}_${ConsentManager.instance.canRequestAds}_${Admob.instance.isShowAllAds}_$isNetwork',
      );
      onAdFailedToLoad?.call(
        'config_$nameConfig,canRequestAds_${ConsentManager.instance.canRequestAds},isShowAllAds_${Admob.instance.isShowAllAds},isNetwork_$isNetwork',
      );
      return;
    }

    final adsPlatform = AmazicAdsFlutterPlatform.instance;

    adsPlatform.onAdLoaded = (id) {
      print('admob_ads --- Inter Ad Preload: onAdLoaded');
      onAdLoaded?.call();
    };

    adsPlatform.onAdFailedToLoad = (id, error) {
      print('admob_ads --- Inter Ad Preload: onAdFailedToLoad');
      EventLog.logEvent('${idAds}_fail', parameters: {'error': error});
      onAdFailedToLoad?.call(error);
    };

    adsPlatform.loadInterAdPreload(idAds, Admob.instance.numberPreload);
  }

  Future<void> showInterAdPreload({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    required Function() onNext,
    required Function()? onAdImpression,
    required Function()? onAdClicked,
    required Function(String)? onAdFailedToShow,
    required Function()? onAdDismiss,
    required String name,
    bool isShowLoading = true,
  }) async {
    var isNetwork = await Admob.instance.isNetworkActive();
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (isNetwork) == false) {
      print('admob_ads --- Inter Ad Preload: can not show');
      EventLog.logEvent(
        '${name}_config_${config}_${ConsentManager.instance.canRequestAds}_${Admob.instance.isShowAllAds}_$isNetwork',
      );
      onNext.call();
      return;
    }

    print('admob_ads --- Inter Ad Preload: start show');
    if (navigatorKey.currentContext != null && isShowLoading) {
      print('admob_ads --- Inter Ad Preload: show dialog loading');
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    final adsPlatform = AmazicAdsFlutterPlatform.instance;

    adsPlatform.onAdClicked = () {
      onAdClicked?.call();
    };
    adsPlatform.onAdDismissed = () {
      print('admob_ads --- Inter Ad Preload: onAdDismissed');
      if (navigatorKey.currentContext != null && isShowLoading) {
        print('admob_ads --- Inter Ad Preload: onAdDismissed - close dialog loading');
        closeLoadingDialog(context: navigatorKey.currentContext!);
      }
      Admob.instance.setFullScreenAdShowing(false);
      AdHelper.setLastTimeDismissInter();

      onAdDismiss?.call();
      onNext();
    };
    adsPlatform.onAdFailedToShow = (id, error) {
      print('admob_ads --- Inter Ad Preload: onAdFailedToShow');
      if (navigatorKey.currentContext != null && isShowLoading) {
        print('admob_ads --- Inter Ad Preload: onAdFailedToShow - close dialog loading');
        closeLoadingDialog(context: navigatorKey.currentContext!);
      }
      Admob.instance.setFullScreenAdShowing(false);

      EventLog.logEvent('${name}_fail', parameters: {'error': error});

      onAdFailedToShow?.call(error);
      onNext();
    };
    adsPlatform.onAdImpression = () {
      print('admob_ads --- Inter Ad Preload: onAdImpression');
      Admob.instance.setFullScreenAdShowing(true);
      EventLog.logEvent('${name}_view');

      onAdImpression?.call();
    };
    adsPlatform.onPaidEvent = (network, valueMicros, currency) {
      AdjustUtil.instance.trackRevenue(
        network: network,
        revenue: valueMicros,
        currency: currency,
        adUnitId: idAds,
        adFormat: name,
      );
    };

    Admob.instance.setFullScreenAdShowing(true);
    Admob.instance.checkAndShowAdForeground(
      onShow: () {
        print('admob_ads --- Inter Ad Preload: show Ads');
        adsPlatform.showInterAdPreload(idAds);
      },
    );
  }

  Future<void> loadAndShowInterAdPreload({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    required Function() onNext,
    required Function()? onAdLoaded,
    required Function(String)? onAdFailedToLoad,
    required Function()? onAdImpression,
    required Function()? onAdClicked,
    required Function(String)? onAdFailedToShow,
    required Function()? onAdDismiss,
    required String name,
  }) async {
    bool? abc = await AmazicAdsFlutterPlatform.instance.isAdAvailableInter(idAds);
    print('admob_ads --- Inter Ad Preload - loadAndShow: isAdAvailable = $abc');
    if (await AmazicAdsFlutterPlatform.instance.isAdAvailableInter(idAds) == true) {
      print('admob_ads --- Inter Ad Preload - loadAndShow: HAVE DATA -> Show Ads');
      EventLog.logEvent('${name}_true');
      showInterAdPreload(
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
      print('admob_ads --- Inter Ad Preload - loadAndShow: NO DATA -> Load And Show Ads');
      var isNetwork = await Admob.instance.isNetworkActive();
      if (config == false ||
          ConsentManager.instance.canRequestAds == false ||
          Admob.instance.isShowAllAds == false ||
          (isNetwork) == false) {
        print('admob_ads --- Inter Ad Preload - loadAndShow: can not load');
        EventLog.logEvent(
          '${name}_config_${config}_${ConsentManager.instance.canRequestAds}_${Admob.instance.isShowAllAds}_$isNetwork',
        );
        onNext.call();
        return;
      }

      if (navigatorKey.currentContext != null) {
        print('admob_ads --- Inter Ad Preload - loadAndShow:  show Dialog loading');

        showLoadingDialog(context: navigatorKey.currentContext!);
      }

      bool isFirstLoadAd = true;
      //load ads
      final adsPlatform = AmazicAdsFlutterPlatform.instance;

      adsPlatform.onAdLoaded = (id) {
        print('admob_ads --- Inter Ad Preload - loadAndShow: onAdLoaded');
        if (isFirstLoadAd) {
          isFirstLoadAd = false;
          onAdLoaded?.call();
          showInterAdPreload(
            navigatorKey: navigatorKey,
            idAds: idAds,
            config: config,
            onNext: onNext,
            onAdImpression: () {
              print('admob_ads --- Inter Ad Preload - loadAndShow: onAdImpression');
              Admob.instance.setFullScreenAdShowing(true);
              onAdImpression?.call();
            },
            onAdClicked: onAdClicked,
            onAdFailedToShow: (error) {
              print('admob_ads --- Inter Ad Preload - loadAndShow: onAdFailedToShow');
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              Admob.instance.setFullScreenAdShowing(false);
              onAdFailedToShow?.call(error);
            },
            onAdDismiss: () {
              print('admob_ads --- Inter Ad Preload - loadAndShow: onAdDismiss');
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              Admob.instance.setFullScreenAdShowing(false);
              AdHelper.setLastTimeDismissInter();
              onAdDismiss?.call();
            },
            name: name,
            isShowLoading: false,
          );
        }
      };

      adsPlatform.onAdFailedToLoad = (id, error) {
        print('admob_ads --- Inter Ad Preload: onAdFailedToLoad - error: $error');
        if (isFirstLoadAd) {
          isFirstLoadAd = false;
          if (navigatorKey.currentContext != null) {
            closeLoadingDialog(context: navigatorKey.currentContext!);
          }
          onAdFailedToLoad?.call(error);
          EventLog.logEvent('${name}_fail', parameters: {'error': error});
          onNext.call();
        }
      };

      adsPlatform.loadInterAdPreload(idAds, Admob.instance.numberPreload);
    }
  }

  Future<void> loadAndShowInterSplashAdPreload({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    Function()? onAdDisable,
    Function()? onAdLoaded,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function(String)? onAdFailedToLoad,
    Function(String)? onAdFailedToShow,
    Function()? onAdDismiss,
  }) async {
    isAdSplashFinished = false;

    ///timeout check 12s
    bool adHasShown = false;
    final timeoutCompleter = Completer<void>(); //kiểm soát timeout 12s
    DateTime startTime = DateTime.now();

    Future.delayed(const Duration(seconds: 20), () {
      if (!adHasShown) {
        print('admob_ads --- Inter Ad Preload Splash: Timeout 20s - cancel show ads splash');
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
        print('admob_ads --- Inter Ad Preload Splash: inter splash đã show Xong hoặc bị False');
        if (!timeoutCompleter.isCompleted) timeoutCompleter.complete();
      }
    }

    //timeout 7s native splash
    if (Admob.instance.isUseNativeSplash) {
      Admob.instance.logEventSplashToStep(nameEvent: 'splash_start_await_7s');
      print('admob_ads --- Inter Ad Preload Splash: start await 7s splash');
      Future.delayed(Duration(seconds: Admob.instance.timeDelayNativeSplash), () {
        Admob.instance.logEventSplashToStep(nameEvent: 'splash_done_await_7s');
        print('admob_ads --- Inter Ad Preload Splash: count done 7s');
        isTimeDelayNativeSplash = true;

        _checkConditionAdPreloadSplash(
          navigatorKey: navigatorKey,
          idAds: idAds,
          startTime: startTime,
          onAdImpression: () {
            handleAdsShown();
            onAdImpression?.call();
          },
          onAdClicked: onAdClicked,
          onAdFailedToShow: onAdFailedToShow,
          onAdDismiss: onAdDismiss,
        );
      });
    } else {
      print('admob_ads --- Inter Ad Preload Splash: do not use delay 7s');
      isTimeDelayNativeSplash = true;
    }

    var isNetwork = await Admob.instance.isNetworkActive();
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (isNetwork) == false) {
      print('admob_ads --- Inter Ad Preload Splash: not load');
      EventLog.logEvent(
        'inter_splash_config_${config}_${ConsentManager.instance.canRequestAds}_${Admob.instance.isShowAllAds}_$isNetwork',
      );
      handleAdsShown();
      onAdDisable?.call();
      return;
    }
    if (navigatorKey.currentContext != null) {
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    EventLog.logEvent('inter_splash_true');

    final adsPlatform = AmazicAdsFlutterPlatform.instance;
    adsPlatform.onAdLoaded = (id) {
      print('admob_ads --- Inter Ad Preload Splash: onAdLoaded');

      onAdLoaded?.call();

      EventLog.logEvent(
        'inter_splash_check_show',
        parameters: {'message': 'isNextTimeoutAdSplash_${isNextTimeoutAd}'},
      );
      print('admob_ads --- inter_splash_check_show isNextTimeoutAdSplash_$isNextTimeoutAd');

      ///show ad splash
      _checkConditionAdPreloadSplash(
        navigatorKey: navigatorKey,
        idAds: idAds,
        startTime: startTime,
        onAdImpression: () {
          handleAdsShown();
          onAdImpression?.call();
        },
        onAdClicked: onAdClicked,
        onAdFailedToShow: onAdFailedToShow,
        onAdDismiss: onAdDismiss,
      );
    };

    adsPlatform.onAdFailedToLoad = (id, error) {
      isAdSplashFinished = true;
      print('admob_ads --- Inter Ad Preload Splash: onAdFailedToLoad');
      EventLog.logEvent('inter_splash_fail', parameters: {'error': error});
      Admob.instance.setFullScreenAdShowing(false);
      if (navigatorKey.currentContext != null) {
        closeLoadingDialog(context: navigatorKey.currentContext!);
      }
      handleAdsShown();
      onAdFailedToLoad?.call(error);
      adsPlatform.destroyInterAdPreload(idAds);
    };

    print('admob_ads --- Inter Ad Preload Splash: load inter splash');
    adsPlatform.loadInterAdPreload(idAds, Admob.instance.numberPreloadSplash);

    print('admob_ads --- inter_ads_splash: đợi timeout xem đã xong hay được huỷ chưa');
    await timeoutCompleter.future;
    print('admob_ads --- inter_ads_splash: timeout ads splash đã xong tiếp tục xử lý');
  }

  void _checkConditionAdPreloadSplash({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required DateTime startTime,
    required Function()? onAdImpression,
    required Function()? onAdClicked,
    required Function(String)? onAdFailedToShow,
    required Function()? onAdDismiss,
  }) {
    if (isTimeDelayNativeSplash && !isNextTimeoutAd && !isAdSplashFinished) {
      // Tính tổng thời gian đã chờ
      double totalWait = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      print("admob_ads --- ===> TỔNG THỜI GIAN CHỜ: $totalWait giây");

      isAdSplashFinished = true;
      showInterSplashAdPreload(
        navigatorKey: navigatorKey,
        idAds: idAds,
        onAdImpression: onAdImpression,
        onAdClicked: onAdClicked,
        onAdFailedToShow: onAdFailedToShow,
        onAdDismiss: onAdDismiss,
      );
    }
  }

  Future<void> showInterSplashAdPreload({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required Function()? onAdImpression,
    required Function()? onAdClicked,
    required Function(String)? onAdFailedToShow,
    required Function()? onAdDismiss,
  }) async {
    final adsPlatform = AmazicAdsFlutterPlatform.instance;
    adsPlatform.onAdClicked = () {
      onAdClicked?.call();
    };
    adsPlatform.onAdDismissed = () {
      print('admob_ads --- Inter Ad Preload Splash: onAdDismissed');
      if (navigatorKey.currentContext != null) {
        closeLoadingDialog(context: navigatorKey.currentContext!);
      }
      Admob.instance.setFullScreenAdShowing(false);
      onAdDismiss?.call();
    };
    adsPlatform.onAdFailedToShow = (id, error) {
      print('admob_ads --- Inter Ad Preload Splash: onAdFailedToShow');
      if (navigatorKey.currentContext != null) {
        closeLoadingDialog(context: navigatorKey.currentContext!);
      }
      Admob.instance.setFullScreenAdShowing(false);
      EventLog.logEvent('inter_splash_fail', parameters: {'error': error});
      onAdFailedToShow?.call(error);
    };
    adsPlatform.onAdImpression = () {
      print('admob_ads --- Inter Ad Preload Splash: onAdImpression');
      adsPlatform.destroyInterAdPreload(idAds);

      Admob.instance.setFullScreenAdShowing(true);
      onAdImpression?.call();
    };
    adsPlatform.onPaidEvent = (network, valueMicros, currency) {
      print(
        'admob_ads --- Inter Ad Preload Splash: onPaidEvent - network: $network - valueMicros: $valueMicros - currency: $currency',
      );
      AdjustUtil.instance.trackRevenue(
        network: network,
        revenue: valueMicros,
        currency: currency,
        adUnitId: idAds,
        adFormat: 'inter_splash_preload',
      );
    };

    Admob.instance.setFullScreenAdShowing(true);
    Admob.instance.checkAndShowAdForeground(
      onShow: () {
        adsPlatform.showInterAdPreload(idAds);
      },
    );
  }

  Future<void> destroy({required String idAds}) async {
    final adsPlatform = AmazicAdsFlutterPlatform.instance;
    adsPlatform.destroyInterAdPreload(idAds);
  }
}
