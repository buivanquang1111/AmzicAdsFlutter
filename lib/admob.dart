import 'dart:async';

import 'package:amazic_ads_flutter/call_api/call_api.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:amazic_ads_flutter/utils/ad_foreground_observer.dart';
import 'package:amazic_ads_flutter/utils/ad_helper.dart';
import 'package:amazic_ads_flutter/utils/adjust_util.dart';
import 'package:amazic_ads_flutter/utils/app_lifecycle_reactor.dart';
import 'package:amazic_ads_flutter/utils/remote_config.dart';
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

  ///token event tracking Adjust
  String _eventTracking = '';

  setEventTrackingAdjust(String value) => _eventTracking = value;

  String get eventTrackingAdjust => _eventTracking;

  Future<void> init({
    required String? linkServer,
    required String? appId,
    required String? packageName,
    required GlobalKey<NavigatorState> navigatorKey,
    required String nameIddAdsResume,
    required bool isShowWelComeScreenAfterAppOpenAds,
    Function()? onGotoScreenWelcomeBack,
    required String nameIdAdsAppOpenSplash,
    required String nameIdAdsInterSplash,
    required String nameConfigAppOpenSplash,
    required String nameConfigInterSplash,
    required String nameRateAoa,
    required Function() onNext,
    required String nameIntervalBetweenInter,
    required String nameIntervalFromStart,
    required String nameIntervalInterAll,
    required Function() onStartLoadBanner,
    required List<RemoteConfigKey> remoteConfigKeys,
    String? eventAdjustTracking,
  }) async {
    ///set event adjust
    if (eventAdjustTracking != null) {
      setEventTrackingAdjust(eventAdjustTracking);
    }

    ///call dong thoi task
    final Completer<void> callIdAdsDoneCompleter = Completer<void>();

    late Future<void> firebaseTask;
    late Future<void> umpTask;
    late Future<void> callIDAdsTask;

    firebaseTask = fetchRemoteFirebase(remoteConfigKeys: remoteConfigKeys);
    umpTask = fetchUMP(
      callIdAdsDoneCompleter.future,
      navigatorKey: navigatorKey,
      nameIdAdsResume: nameIddAdsResume,
      isShowWelComeScreenAfterAppOpenAds: isShowWelComeScreenAfterAppOpenAds,
      nameIdAdsAppOpenSplash: nameIdAdsAppOpenSplash,
      nameIdAdsInterSplash: nameIdAdsInterSplash,
      nameConfigAppOpenSplash: nameConfigAppOpenSplash,
      nameConfigInterSplash: nameConfigInterSplash,
      nameRateAoa: nameRateAoa,
      onNext: onNext,
      nameIntervalBetweenInter: nameIntervalBetweenInter,
      nameIntervalFromStart: nameIntervalFromStart,
      nameIntervalInterAll: nameIntervalInterAll,
      onStartLoadBanner: onStartLoadBanner,
    );
    callIDAdsTask = fetchApiAds(
      linkServer: linkServer,
      appId: appId,
      packageName: packageName,
      onResponse: () {
        callIdAdsDoneCompleter.complete();
      },
      onError: (p0) {

      },
    );

    final Map<String, Future<void>> tasks = {
      'FIREBASE_REMOTE': firebaseTask,
      'UMP': umpTask,
      'CALL_ID_ADS': callIDAdsTask,
    };

    // Đánh dấu tiến trình đã hoàn thành hay chưa
    final Map<String, bool> taskCompleted = {
      'FIREBASE_REMOTE': false,
      'UMP': false,
      'CALL_ID_ADS': false,
    };

    // Chạy các tiến trình đồng thời
    tasks.forEach((key, future) {
      future
          .then((_) {
            taskCompleted[key] = true;
            print('admob_ads --- ✅ Đã hoàn thành task: $key');
          })
          .catchError((e) {
            print('admob_ads --- ⚠️ Lỗi ở task: $key - $e');
          });
    });

    // Đợi 12 giây
    await Future.delayed(const Duration(seconds: 12));

    // Kiểm tra tiến trình chưa hoàn thành
    final notFinished = taskCompleted.entries.where((e) => !e.value).map((e) => e.key).toList();

    if (notFinished.isNotEmpty) {
      print('admob_ads --- ⏰ Sau 12 giây, các task chưa hoàn thành là:');
      for (var task in notFinished) {
        print('admob_ads --- ❌ Task chưa xong: $task');
      }
    } else {
      print('admob_ads --- 🎉 Tất cả task đã hoàn thành trong vòng 12 giây');
    }

    // runConcurrentTasksWithDependency();
  }

  ///test call dong thoi
  Future<void> runConcurrentTasksWithDependency() async {
    final Completer<void> remoteDoneCompleter = Completer<void>();

    late Future<void> imageTask;
    late Future<void> remoteTask;
    late Future<void> otherTask;

    imageTask = fetchImageData(remoteDoneCompleter.future); // truyền Future
    remoteTask = fetchRemote().then((_) {
      print('✅ [FIREBASE_REMOTE] Done');
      remoteDoneCompleter.complete(); // thông báo là đã xong
    });
    otherTask = fetchOtherApi();

    // Chạy đồng thời cả 3 task
    final tasks = {'API_IMAGE': imageTask, 'FIREBASE_REMOTE': remoteTask, 'API_OTHER': otherTask};

    final taskCompleted = {'API_IMAGE': false, 'FIREBASE_REMOTE': false, 'API_OTHER': false};
    print('✅ start all');
    for (final entry in tasks.entries) {
      entry.value.then((_) {
        taskCompleted[entry.key] = true;
      });
    }

    await Future.delayed(Duration(seconds: 12));

    final notFinished = taskCompleted.entries.where((e) => !e.value).map((e) => e.key).toList();

    if (notFinished.isNotEmpty) {
      for (var task in notFinished) {
        print('❌ Task chưa xong: $task');
      }
    } else {
      print('✅ Tất cả task đã xong trong 12s');
    }
  }

  Future<void> fetchImageData(Future remoteDone) async {
    print('➡️ [API_IMAGE] Start fetch');
    await Future.delayed(Duration(seconds: 5)); // giả lập fetch ảnh
    print('✅ [API_IMAGE] Done fetch, đợi remote...');
    await remoteDone; // Đợi firebase xong mới làm tiếp
    print('🚀 [API_IMAGE] Tiếp tục xử lý sau khi có dữ liệu remote');
  }

  Future<void> fetchRemote() async {
    print('➡️ [FIREBASE_REMOTE] Start fetch');
    await Future.delayed(Duration(seconds: 14));
  }

  Future<void> fetchOtherApi() async {
    print('➡️ [API_OTHER] Start fetch');
    await Future.delayed(Duration(seconds: 8));
    print('✅ [API_OTHER] Done');
  }

  ///end call dong thoi

  Future<void> fetchUMP(
    Future callIdAdsDone, {
    required GlobalKey<NavigatorState> navigatorKey,
    required String nameIdAdsResume,
    required bool isShowWelComeScreenAfterAppOpenAds,
    Function()? onGotoScreenWelcomeBack,
    required String nameIdAdsAppOpenSplash,
    required String nameIdAdsInterSplash,
    required String nameConfigAppOpenSplash,
    required String nameConfigInterSplash,
    required String nameRateAoa,
    required Function() onNext,
    required String nameIntervalBetweenInter,
    required String nameIntervalFromStart,
    required String nameIntervalInterAll,
    required Function() onStartLoadBanner,
  }) async {
    print('admob_ads --- ▶️ Bắt đầu UMP');
    //init UMP
    await ConsentManager.instance.handleRequestUmp(
      onPostExecute: () async {
        if (ConsentManager.instance.canRequestAds) {
          print('admob_ads --- ✅ Done UMP, await call id ads');
          await callIdAdsDone;
          print('admob_ads --- 🚀 Continue process show ads splash');
          onStartLoadBanner();

          ///init app open resume
          appLifecycleReactor = AppLifecycleReactor(
            navigatorKey: navigatorKey,
            idAds: CallApi.instance.getListIDByName(nameIdAdsResume)[0],
            config: true,
            isShowWelComeScreenAfterAppOpenAds: isShowWelComeScreenAfterAppOpenAds,
            onGotoWelcomeBack: onGotoScreenWelcomeBack,
          );
          appLifecycleReactor?.listenToAppStateChanges();

          ///init ads splash
          AdHelper.init(
            intervalBetweenInter: RemoteConfig.getInt(nameIntervalBetweenInter) * 1000,
            intervalFromStart: RemoteConfig.getInt(nameIntervalFromStart) * 1000,
            intervalInterAll: RemoteConfig.getInt(nameIntervalInterAll) * 1000,
            configAppOpen: RemoteConfig.getBool(nameConfigAppOpenSplash),
            configInter: RemoteConfig.getBool(nameConfigInterSplash),
            rateAoa: RemoteConfig.getString(nameRateAoa),
          );
          initAndShowAdSplash(
            navigatorKey: navigatorKey,
            idAdsAppOpen: CallApi.instance.getListIDByName(nameIdAdsAppOpenSplash)[0],
            idAdsInter: CallApi.instance.getListIDByName(nameIdAdsInterSplash)[0],
            configAppOpen: RemoteConfig.getBool(nameConfigAppOpenSplash),
            configInter: RemoteConfig.getBool(nameConfigInterSplash),
            onNext: onNext,
          );
        } else {
          onNext();
        }
      },
    );
    print('admob_ads --- ✅ Kết thúc UMP');
  }

  Future<void> fetchRemoteFirebase({required List<RemoteConfigKey> remoteConfigKeys}) async {
    print('admob_ads --- ▶️ Bắt đầu FIREBASE_REMOTE');
    // await Future.delayed(const Duration(seconds: 14));
    await RemoteConfig.init(remoteConfigKeys: remoteConfigKeys);
    print('admob_ads --- ✅ Kết thúc FIREBASE_REMOTE');
  }

  Future<void> fetchApiAds({
    required String? linkServer,
    required String? appId,
    required String? packageName,
    required Function() onResponse,
    required Function(String) onError,
  }) async {
    print('admob_ads --- ▶️ Bắt đầu CALL_ID_ADS');
    await CallApi.instance.callAds(
      linkServer: linkServer,
      appId: appId,
      packageName: packageName,
      onResponse: onResponse,
      onError: onError,
    );
    print('admob_ads --- ✅ Kết thúc CALL_ID_ADS');
  }

  ///end

  Future<void> initAdmob() async {
    MobileAds.instance.initialize();
  }

  Future<String?> getPlatformVersion() {
    return AmazicAdsFlutterPlatform.instance.getPlatformVersion();
  }

  Future<bool?> getConsentResult() async {
    final canRequest = await AmazicAdsFlutterPlatform.instance.getConsentResult();
    print('admob_ads --- ump: getConsentResult - $canRequest');
    return canRequest;
  }

  Future<bool?> isNetworkActive() async {
    final isConnected = await AmazicAdsFlutterPlatform.instance.isNetworkActive();
    print('admob_ads --- have_internet: $isConnected');
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
    bool isShowAdSplash = false,
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
              setFullScreenAdShowing(true);
              onAdImpression?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('admob_ads --- inter_ads: onAdFailedToShowFullScreenContent ${error.message}');
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
              if (isShowAdSplash == false) {
                AdHelper.setLastTimeDismissInter();
              }
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
              ad.setImmersiveMode(true);
              ad.show();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('admob_ads --- inter_ads: onAdFailedToLoad ${error.message}');
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
    Function()? onUserEarnedReward,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        isShowAllAds == false ||
        (await isNetworkActive()) == false) {
      print('admob_ads --- reward_ads: not load');
      onAdDisable?.call();
      return;
    }
    print('admob_ads --- reward_ads: start request');
    if (navigatorKey.currentContext != null) {
      showLoadingDialog(context: navigatorKey.currentContext!);
    }

    RewardedAd.load(
      adUnitId: idAds,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('admob_ads --- reward_ads: onAdLoaded');
          onAdLoaded?.call();

          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            print('admob_ads --- reward_ads: onPaidEvent');
            AdjustUtil.instance.trackRevenue(
              network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
              revenue: valueMicros,
              currency: currencyCode,
            );
          };

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('admob_ads --- reward_ads: onAdShowedFullScreenContent');
            },
            onAdImpression: (ad) {
              print('admob_ads --- reward_ads: onAdImpression');
              setFullScreenAdShowing(true);
              onAdImpression?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('admob_ads --- reward_ads: onAdFailedToShowFullScreenContent');
              setFullScreenAdShowing(false);
              ad.dispose();
              onAdFailedToShow?.call();
            },
            onAdDismissedFullScreenContent: (ad) {
              print('admob_ads --- reward_ads: onAdDismissedFullScreenContent');
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              setFullScreenAdShowing(false);
              ad.dispose();
              onAdDismiss?.call();
            },
            onAdClicked: (ad) {
              print('admob_ads --- reward_ads: onAdClicked');
              onAdClicked?.call();
            },
          );
          setFullScreenAdShowing(true);
          checkAndShowAdForeground(
            onShow: () {
              print('admob_ads --- reward_ads: show');
              ad.setImmersiveMode(true);
              ad.show(
                onUserEarnedReward: (ad, reward) {
                  print('admob_ads --- reward_ads: onUserEarnedReward');
                  onUserEarnedReward?.call();
                },
              );
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('admob_ads --- reward_ads: onAdFailedToLoad');
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
        isShowAdSplash: true,
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

  Future<void> loadAndShowInterInterval({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    required bool isInterAll,
    Function()? onAdDisable,
    Function()? onAdLoaded,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function()? onAdFailedToLoad,
    Function()? onAdFailedToShow,
    Function()? onAdDismiss,
  }) async {
    if (AdHelper.canShowNextInter(isInterAll: isInterAll)) {
      print(
        'admob_ads --- inter_ads: canShowNextInter = ${AdHelper.canShowNextInter(isInterAll: isInterAll)}',
      );
      loadAndShowInterAds(
        navigatorKey: navigatorKey,
        idAds: idAds,
        config: config,
        onAdDisable: onAdDisable,
        onAdFailedToShow: onAdFailedToShow,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdDismiss: onAdDismiss,
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdLoaded: onAdLoaded,
      );
    } else {
      print(
        'admob_ads --- inter_ads: not canShowNextInter = ${AdHelper.canShowNextInter(isInterAll: isInterAll)}',
      );
      onAdDisable?.call();
    }
  }

  Future<void> loadRewardAd({
    required String idAds,
    required bool config,
    required Function(RewardedAd) onAdLoaded,
    required Function() onAdFailedToLoad,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        isShowAllAds == false ||
        (await isNetworkActive()) == false) {
      print('admob_ads --- reward_ads - load_before: not load');
      return;
    }

    print('admob_ads --- reward_ads - load_before: start request');

    RewardedAd.load(
      adUnitId: idAds,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('admob_ads --- reward_ads - load_before: onAdLoaded');
          onAdLoaded.call(ad);
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            print('admob_ads --- reward_ads - load_before: onPaidEvent');
            AdjustUtil.instance.trackRevenue(
              network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
              revenue: valueMicros,
              currency: currencyCode,
            );
          };
        },
        onAdFailedToLoad: (error) {
          print('admob_ads --- reward_ads - load_before: onAdFailedToLoad - $error}');
          onAdFailedToLoad.call();
        },
      ),
    );
  }

  Future<void> showRewardAd({
    required RewardedAd? rewardedAd,
    required bool config,
    required Function() onAdImpression,
    required Function() onAdClicked,
    required Function() onAdFailedToShow,
    required Function() onAdDismiss,
    required Function() onUserEarnedReward,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        isShowAllAds == false ||
        (await isNetworkActive()) == false) {
      print('admob_ads --- reward_ads - load_before: not show');
      return;
    }
    if (rewardedAd != null) {
      rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdImpression: (ad) {
          print('admob_ads --- reward_ads - load_before: onAdImpression');
          onAdImpression.call();
        },
        onAdClicked: (ad) {
          print('admob_ads --- reward_ads - load_before: onAdClicked');
          onAdClicked.call();
        },
        onAdDismissedFullScreenContent: (ad) {
          print('admob_ads --- reward_ads - load_before: onAdDismissedFullScreenContent');
          onAdDismiss.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('admob_ads --- reward_ads - load_before: onAdFailedToShowFullScreenContent');
          onAdFailedToShow.call();
        },
        onAdShowedFullScreenContent: (ad) {
          print('admob_ads --- reward_ads - load_before: onAdShowedFullScreenContent');
        },
        onAdWillDismissFullScreenContent: (ad) {
          print('admob_ads --- reward_ads - load_before: onAdWillDismissFullScreenContent');
        },
      );
      print('admob_ads --- reward_ads - load_before: show');
      rewardedAd.show(
        onUserEarnedReward: (ad, reward) {
          print('admob_ads --- reward_ads - load_before: onUserEarnedReward');
          onUserEarnedReward.call();
        },
      );
    } else {
      print('admob_ads --- reward_ads - load_before: not show rewardAd - null');
    }
  }
}
