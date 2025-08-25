import 'dart:async';

import 'package:amazic_ads_flutter/amazic_ads_flutter.dart';
import 'package:amazic_ads_flutter/call_api/call_api.dart';
import 'package:amazic_ads_flutter/manager_ad/app_open_manager.dart';
import 'package:amazic_ads_flutter/manager_ad/inter_ads_manager.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:amazic_ads_flutter/utils/ad_foreground_observer.dart';
import 'package:amazic_ads_flutter/utils/ad_helper.dart';
import 'package:amazic_ads_flutter/utils/app_lifecycle_reactor.dart';
import 'package:amazic_ads_flutter/utils/event_log.dart';
import 'package:amazic_ads_flutter/utils/preferences_util.dart';
import 'package:amazic_ads_flutter/utils/remote_config.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'amazic_ads_flutter_platform_interface.dart';

class Admob {
  Admob._Admob();

  static final Admob instance = Admob._Admob();

  GlobalKey<NavigatorState>? navigatorKey;

  bool _isAdmobInitialized = false;

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

  ///timeout check 12s
  bool isNextTimeout = false; // biến check xem đã chuyển màn trong timeout splash
  bool isTimeoutSplash = false;
  final timeoutSplashCompleter = Completer<void>();

  void handleTimeOut() {
    if (!isTimeoutSplash) {
      isTimeoutSplash = true;
      print('admob_ads --- handle Timeout kết thúc check timeout');
      if (!timeoutSplashCompleter.isCompleted) timeoutSplashCompleter.complete();
    }
  }

  ///đếm thời gian từ lúc vào màn đến khi show ads splash
  final stopWatch = Stopwatch();

  ///list danh sách các vị trí remote config false khi là Detect Test Ad
  List<String> _detectedTestAds = [];

  void addDetectedTestAd(String adUnitId) {
    if (!_detectedTestAds.contains(adUnitId)) {
      _detectedTestAds.add(adUnitId);
    }
  }

  List<String> get detectedTestAds => _detectedTestAds;

  bool isAdUnitDetected(String adUnitId) {
    return _detectedTestAds.contains(adUnitId);
  }

  Future<void> init({
    required String? linkServer,
    required String? appId,
    required String? packageName,
    required GlobalKey<NavigatorState> navigatorKey,
    required String nameIddAdsResume,
    required String nameResumeConfig,
    required String nameIdAdsAppOpenSplash,
    required String nameIdAdsInterSplash,
    required String nameConfigAppOpenSplash,
    required String nameConfigInterSplash,
    required String nameRateAoa,
    required String nameIntervalBetweenInter,
    required String nameIntervalFromStart,
    required String nameIntervalInterAll,
    required bool isShowWelComeScreenAfterAppOpenAds,
    Function()? onGotoScreenWelcomeBack,
    required Function() onNext,
    required Function() onStartLoadBanner,
    required List<RemoteConfigKey> remoteConfigKeys,
    String? eventAdjustTracking,
  }) async {
    ///start count time show ads
    stopWatch.start();

    ///init Preferences
    await PreferencesUtil.init();
    PreferencesUtil.increaseCountOpenApp();

    ///logevent internet
    if (await isNetworkActive() == true) {
      EventLog.logEvent('splash_have_internet');
    }

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
      nameResumeConfig: nameResumeConfig,
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
      onGotoScreenWelcomeBack: onGotoScreenWelcomeBack,
    );
    callIDAdsTask = fetchApiAds(
      linkServer: linkServer,
      appId: appId,
      packageName: packageName,
      onResponse: () {
        callIdAdsDoneCompleter.complete();
      },
      onError: (p0) {},
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
    await Future.delayed(const Duration(seconds: 12), () {
      if (!isTimeoutSplash) {
        print('admob_ads --- Timeout Splash 12s');
        EventLog.logEvent('timeout_splash_12s');
        timeoutSplashCompleter.complete();
        isNextTimeout = true;
        onNext();
        print('admob_ads --- onNext Timeout Splash 12s');
      }
    });

    // Kiểm tra tiến trình chưa hoàn thành
    final notFinished = taskCompleted.entries.where((e) => !e.value).map((e) => e.key).toList();

    if (notFinished.isNotEmpty) {
      print('admob_ads --- ⏰ Sau 12 giây, các task chưa hoàn thành là:');
      for (var task in notFinished) {
        print('admob_ads --- ❌ Task chưa xong: $task');
      }
    } else {
      print('admob_ads --- 🎉 Tất cả task đã hoàn thành trong vòng <= 12 giây');
    }

    // runConcurrentTasksWithDependency();
  }

  ///test call dong thoi
  // Future<void> runConcurrentTasksWithDependency() async {
  //   final Completer<void> remoteDoneCompleter = Completer<void>();
  //
  //   late Future<void> imageTask;
  //   late Future<void> remoteTask;
  //   late Future<void> otherTask;
  //
  //   imageTask = fetchImageData(remoteDoneCompleter.future); // truyền Future
  //   remoteTask = fetchRemote().then((_) {
  //     print('✅ [FIREBASE_REMOTE] Done');
  //     remoteDoneCompleter.complete(); // thông báo là đã xong
  //   });
  //   otherTask = fetchOtherApi();
  //
  //   // Chạy đồng thời cả 3 task
  //   final tasks = {'API_IMAGE': imageTask, 'FIREBASE_REMOTE': remoteTask, 'API_OTHER': otherTask};
  //
  //   final taskCompleted = {'API_IMAGE': false, 'FIREBASE_REMOTE': false, 'API_OTHER': false};
  //   print('✅ start all');
  //   for (final entry in tasks.entries) {
  //     entry.value.then((_) {
  //       taskCompleted[entry.key] = true;
  //     });
  //   }
  //
  //   await Future.delayed(Duration(seconds: 12));
  //
  //   final notFinished = taskCompleted.entries.where((e) => !e.value).map((e) => e.key).toList();
  //
  //   if (notFinished.isNotEmpty) {
  //     for (var task in notFinished) {
  //       print('❌ Task chưa xong: $task');
  //     }
  //   } else {
  //     print('✅ Tất cả task đã xong trong 12s');
  //   }
  // }
  //
  // Future<void> fetchImageData(Future remoteDone) async {
  //   print('➡️ [API_IMAGE] Start fetch');
  //   await Future.delayed(Duration(seconds: 5)); // giả lập fetch ảnh
  //   print('✅ [API_IMAGE] Done fetch, đợi remote...');
  //   await remoteDone; // Đợi firebase xong mới làm tiếp
  //   print('🚀 [API_IMAGE] Tiếp tục xử lý sau khi có dữ liệu remote');
  // }
  //
  // Future<void> fetchRemote() async {
  //   print('➡️ [FIREBASE_REMOTE] Start fetch');
  //   await Future.delayed(Duration(seconds: 14));
  // }
  //
  // Future<void> fetchOtherApi() async {
  //   print('➡️ [API_OTHER] Start fetch');
  //   await Future.delayed(Duration(seconds: 8));
  //   print('✅ [API_OTHER] Done');
  // }
  ///end call dong thoi

  Future<void> fetchUMP(
    Future callIdAdsDone, {
    required GlobalKey<NavigatorState> navigatorKey,
    required String nameIdAdsResume,
    required String nameResumeConfig,
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
            nameResumeConfig: nameResumeConfig,
            isShowWelComeScreenAfterAppOpenAds: isShowWelComeScreenAfterAppOpenAds,
            onGotoWelcomeBack: onGotoScreenWelcomeBack,
            name: nameIdAdsResume,
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

          handleTimeOut();

          if (!isNextTimeout) {
            initAndShowAdSplash(
              navigatorKey: navigatorKey,
              idAdsAppOpen: CallApi.instance.getListIDByName(nameIdAdsAppOpenSplash)[0],
              idAdsInter: CallApi.instance.getListIDByName(nameIdAdsInterSplash)[0],
              configAppOpen: RemoteConfig.getBool(nameConfigAppOpenSplash),
              configInter: RemoteConfig.getBool(nameConfigInterSplash),
              rateAoa: RemoteConfig.getString(nameRateAoa),
              onNext: onNext,
            );
          }
        } else {
          handleTimeOut();
          if (!isNextTimeout) {
            print('admob_ads --- onNext DO NOT CONSENT');
            onNext();
          }
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
    // await Future.delayed(const Duration(seconds: 14));
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

  // Future<void> initAdmob() async {
  //   MobileAds.instance.initialize();
  // }
  Future<void> initAdmob() async {
    if (_isAdmobInitialized) {
      return;
    }

    MobileAds.instance.initialize().then((value) {
      print("=== Mediation AdMob Initialization Status ===");
      value.adapterStatuses.forEach((key, status) {
        final state = status.state;
        final description = status.description;

        print("  Adapter: $key");
        print("  State: $state");
        print("  Description: $description");

        if (state == AdapterInitializationState.notReady) {
          print("  ⚠️ This adapter is NOT READY. Check SDK setup, app ID, or initialization code.");
        } else if (state == AdapterInitializationState.ready) {
          print("  ✅ Ready to serve ads.");
        }
      });
      print("=== End of Adapter Status ===");
    });

    _isAdmobInitialized = true;
  }

  Future<void> openMediationTest() async{

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
    required String name,
  }) async {
    InterAdsManager.instance.loadAndShowInterAds(
      navigatorKey: navigatorKey,
      idAds: idAds,
      config: config,
      onAdDisable: onAdDisable,
      onAdLoaded: onAdLoaded,
      onAdImpression: onAdImpression,
      onAdClicked: onAdClicked,
      onAdFailedToLoad: onAdFailedToLoad,
      onAdFailedToShow: onAdFailedToShow,
      onAdDismiss: onAdDismiss,
      name: name,
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
    required String name,
  }) async {
    RewardAdManager.instance.loadAndShowRewardAds(
      navigatorKey: navigatorKey,
      idAds: idAds,
      config: config,
      onAdDisable: onAdDisable,
      onAdLoaded: onAdLoaded,
      onAdImpression: onAdImpression,
      onAdClicked: onAdClicked,
      onAdFailedToLoad: onAdFailedToLoad,
      onAdFailedToShow: onAdFailedToShow,
      onAdDismiss: onAdDismiss,
      onUserEarnedReward: onUserEarnedReward,
      name: name,
    );
  }

  Future<void> loadRewardAdConsecutive({required String idAds, required bool config}) async {
    RewardAdManager.instance.loadRewardAdConsecutive(idAds: idAds, config: config);
  }

  Future<void> showRewardConsecutive({
    required String idAds,
    required bool config,
    required int count,
    required VoidCallback onCompleted,
    required String name,
  }) async {
    RewardAdManager.instance.showRewardConsecutive(
      idAds: idAds,
      config: config,
      count: count,
      onCompleted: onCompleted,
      name: name,
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
    required String name,
  }) async {
    AppOpenManager.instance.loadAndShowAppOpenAds(
      navigatorKey: navigatorKey,
      idAds: idAds,
      config: config,
      onAdDisable: onAdDisable,
      onAdLoaded: onAdLoaded,
      onAdImpression: onAdImpression,
      onAdClicked: onAdClicked,
      onAdFailedToLoad: onAdFailedToLoad,
      onAdFailedToShow: onAdFailedToShow,
      onAdDismiss: onAdDismiss,
      name: name,
    );
  }

  Future<void> initAndShowAdSplash({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAdsAppOpen,
    required String idAdsInter,
    required bool configAppOpen,
    required bool configInter,
    required String rateAoa,
    required Function() onNext,
  }) async {
    if (AdHelper.splashType == AdsSplashType.open) {
      AppOpenManager.instance.loadAndShowAppOpenSplash(
        navigatorKey: navigatorKey,
        idAds: idAdsAppOpen,
        config: configAppOpen,
        onAdDisable: () {
          Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
          onNext();
          print('admob_ads --- onNext onAdDisable Ads Splash');
        },
        onAdLoaded: () {},
        onAdImpression: () {
          ///stop dem time show ads
          stopWatch.stop();
          final secondsShowAds = stopWatch.elapsed.inSeconds;
          print('admob_ads --- open_splash: time show ads splash - $secondsShowAds');
          EventLog.logEvent(
            'inter_splash_showad_time',
            parameters: {'showad_time': '${configAppOpen}_$secondsShowAds'},
          );

          EventLog.logEvent('inter_splash_impression_${PreferencesUtil.getCountOpenApp()}');
        },
        onAdClicked: () {
          EventLog.logEvent('inter_splash_click_${PreferencesUtil.getCountOpenApp()}');
        },
        onAdFailedToLoad: () {
          Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
          onNext();
        },
        onAdFailedToShow: () {
          Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
          onNext();
        },
        onAdDismiss: () {
          Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
          onNext();
        },
      );
    } else if (AdHelper.splashType == AdsSplashType.inter) {
      InterAdsManager.instance.loadAndShowInterSplash(
        navigatorKey: navigatorKey,
        idAds: idAdsInter,
        config: configInter,
        onAdLoaded: () {},
        onAdImpression: () {
          ///stop dem time show ads
          stopWatch.stop();
          final secondsShowAds = stopWatch.elapsed.inSeconds;
          print('admob_ads --- inter_splash: time show ads splash - $secondsShowAds');
          EventLog.logEvent(
            'inter_splash_showad_time',
            parameters: {'showad_time': '${configAppOpen}_$secondsShowAds'},
          );

          EventLog.logEvent('inter_splash_impression_${PreferencesUtil.getCountOpenApp()}');
        },
        onAdClicked: () {
          EventLog.logEvent('inter_splash_click_${PreferencesUtil.getCountOpenApp()}');
        },
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

    ///logEvent
    final isHaveInternet = await isNetworkActive();
    final ump = await getConsentResult();
    EventLog.logEvent(
      'inter_splash_tracking',
      parameters: {
        'splash_detail': '${ump}_${isHaveInternet}_${isShowAllAds}_$rateAoa',
        'ump': '$ump',
        'haveinternet': '$isHaveInternet',
        'showallad': '$isShowAllAds',
        'interremote_openremote_aoavalue': '${configInter}_${configAppOpen}_$rateAoa',
      },
    );
  }

  ///show cho trường hợp bị timeout id ads splash => thuong se show tai nut tick man Language
  Future<void> showAdsSplash({
    required GlobalKey<NavigatorState> navigatorKey,
    required Function() onNext,
  }) async {
    if (InterAdsManager.instance.mInterstitialAdSplash == null &&
        AppOpenManager.instance.mAppOpenAdSplash == null) {
      onNext();
    } else {
      if (InterAdsManager.instance.mInterstitialAdSplash != null) {
        InterAdsManager.instance.showInterAdsSplash(
          navigatorKey: navigatorKey,
          onAdImpression: () {},
          onAdClicked: () {},
          onAdFailedToShow: () {
            onNext();
          },
          onAdDismiss: () {
            onNext();
          },
        );
      } else if (AppOpenManager.instance.mAppOpenAdSplash != null) {
        AppOpenManager.instance.showAppOpenAdsSplash(
          navigatorKey: navigatorKey,
          onAdImpression: () {},
          onAdClicked: () {},
          onAdFailedToShow: () {
            onNext();
          },
          onAdDismiss: () {
            onNext();
          },
        );
      }
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
    required String name,
  }) async {
    if (AdHelper.canShowNextInter(isInterAll: isInterAll)) {
      print(
        'admob_ads --- inter_ads: canShowNextInter = ${AdHelper.canShowNextInter(isInterAll: isInterAll)}',
      );
      loadAndShowInterAds(
        navigatorKey: navigatorKey,
        idAds: idAds,
        config: config,
        onAdDisable: () {
          if (isInterAll == true) {
            AdHelper.isFirstShowInterAll = true;
          }
          onAdDisable?.call();
        },
        onAdFailedToShow: () {
          if (isInterAll == true) {
            AdHelper.isFirstShowInterAll = true;
          }
          onAdFailedToShow?.call();
        },
        onAdFailedToLoad: () {
          if (isInterAll == true) {
            AdHelper.isFirstShowInterAll = true;
          }
          onAdFailedToLoad?.call();
        },
        onAdDismiss: () {
          if (isInterAll == true) {
            AdHelper.isFirstShowInterAll = true;
          }
          onAdDismiss?.call();
        },
        onAdClicked: onAdClicked,
        onAdImpression: onAdImpression,
        onAdLoaded: onAdLoaded,
        name: name,
      );
    } else {
      print(
        'admob_ads --- inter_ads: not canShowNextInter = ${AdHelper.canShowNextInter(isInterAll: isInterAll)}',
      );
      onAdDisable?.call();
    }
  }
}
