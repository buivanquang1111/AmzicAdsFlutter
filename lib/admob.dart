import 'dart:async';

import 'package:amazic_ads_flutter/admob_config.dart';
import 'package:amazic_ads_flutter/call_api/call_api.dart';
import 'package:amazic_ads_flutter/manager_ad/app_open_manager.dart';
import 'package:amazic_ads_flutter/manager_ad/inter_ads_manager.dart';
import 'package:amazic_ads_flutter/manager_ad/reward_ad_manager.dart';
import 'package:amazic_ads_flutter/splash_ads/native_after_inter_handler.dart';
import 'package:amazic_ads_flutter/splash_ads/splash_ads_controller.dart';
import 'package:amazic_ads_flutter/utils/ad_foreground_observer.dart';
import 'package:amazic_ads_flutter/utils/ad_helper.dart';
import 'package:amazic_ads_flutter/utils/admob_platform_service.dart';
import 'package:amazic_ads_flutter/utils/app_lifecycle_reactor.dart';
import 'package:amazic_ads_flutter/utils/remote_config.dart';
import 'package:flutter/material.dart';

/// Facade duy nhất mà app dùng thư viện gọi vào (`Admob.instance.xxx`).
///
/// Toàn bộ logic khởi tạo/luồng splash được tách sang
/// `splash_ads/splash_ads_controller.dart` (package `splash_ads`), các cờ
/// cấu hình được gom vào [AdmobConfig], và các lời gọi platform channel
/// được gom vào `AdmobPlatformService`. Class này chỉ giữ vai trò
/// forward + là nơi lưu 1 vài state runtime (navigatorKey,
/// appLifecycleReactor) — API public (tên hàm, tên getter/setter, chữ ký)
/// giữ nguyên 100% so với trước khi tách, nên code ở app khác không cần
/// sửa gì.
class Admob {
  Admob._Admob();

  static final Admob instance = Admob._Admob();

  GlobalKey<NavigatorState>? navigatorKey;

  /// Gom các cờ cấu hình/trạng thái vào 1 object cho gọn, xem [AdmobConfig].
  final AdmobConfig _config = AdmobConfig();

  ///ads app open
  AppLifecycleReactor? appLifecycleReactor;

  ///enable show full ads
  setShowAllAds(bool value) => _config.isShowAllAds = value;

  bool get isShowAllAds => _config.isShowAllAds;

  ///true when ads show full screen
  setFullScreenAdShowing(bool value) => _config.isFullScreenAdShowing = value;

  bool get isFullScreenAdShowing => _config.isFullScreenAdShowing;

  ///token event tracking Adjust
  setEventTrackingAdjust(String value) => _config.eventTrackingAdjust = value;

  String get eventTrackingAdjust => _config.eventTrackingAdjust;

  ///check when show dialog loading hide ads CollapsibleNative
  ValueNotifier<bool> get isShowDialogLoadingAds => _config.isShowDialogLoadingAds;

  void showLoading() {
    isShowDialogLoadingAds.value = true;
  }

  void hideLoading() {
    isShowDialogLoadingAds.value = false;
  }

  ///list danh sách các vị trí remote config false khi là Detect Test Ad
  void addDetectedTestAd(String adUnitId) => _config.addDetectedTestAd(adUnitId);

  List<String> get detectedTestAds => _config.detectedTestAds;

  bool isAdUnitDetected(String adUnitId) => _config.isAdUnitDetected(adUnitId);

  //use ad preload
  setUseAdPreloading(bool value) => _config.isUseAdPreloading = value;

  bool get isUseAdPreloading => _config.isUseAdPreloading;

  //number buffer preload
  setNumberPreload(int value) => _config.numberPreload = value;

  int get numberPreload => _config.numberPreload;

  //number buffer preload splash
  setNumberPreloadSplash(int value) => _config.numberPreloadSplash = value;

  int get numberPreloadSplash => _config.numberPreloadSplash;

  ///native after inter ( moi dung cho moi man Splash)
  setUseNativeAfterInter(bool value) => _config.isUseNativeAfterInter = value;

  bool get isUseNativeAfterInter => _config.isUseNativeAfterInter;

  //json id default
  setJsonIdAdsDefault(String json) => _config.jsonIdAdsDefault = json;

  String get jsonIdAdsDefault => _config.jsonIdAdsDefault;

  ///timeout (giây) chờ 3 task song song lúc splash, mặc định 20s
  setTimeoutScreenSplash(int value) => _config.timeoutScreenSplash = value;

  int get timeoutScreenSplash => _config.timeoutScreenSplash;

  ///===================== Splash / init flow =====================
  ///Toàn bộ logic thực thi nằm ở SplashAdsController (package splash_ads).

  ///Đã bỏ hẳn nameIdAdsAppOpenSplash/nameConfigAppOpenSplash/nameRateAoa -
  ///SplashAdsController không còn dùng App Open Splash / rateAoa để quyết
  ///định show ads splash nữa. App nào đang gọi Admob.instance.init(...) với
  ///3 tham số này cần bỏ chúng ra khi update lên bản này.
  Future<void> init({
    required String linkServer,
    required String appId,
    required String packageName,
    required String jsonIdAdsDefault,
    required GlobalKey<NavigatorState> navigatorKey,
    required String nameIddAdsResume,
    required String nameResumeConfig,
    required String nameIdAdsInterSplash,
    String? nameIdAdsNativeAfterInter,
    required String nameConfigInterSplash,
    String? nameConfigNativeAfterInter,
    required String nameIntervalBetweenInter,
    required String nameIntervalFromStart,
    required String nameIntervalInterAll,
    required bool isShowWelComeScreenAfterAppOpenAds,
    Function()? onGotoScreenWelcomeBack,
    required Function() onNext,
    required Function() onStartLoadBanner,
    required List<RemoteConfigKey> remoteConfigKeys,
    String? eventAdjustTracking,
    ///Cho phép app set lại CallApi.instance.isUsingIdDebug (xem
    ///call_api.dart - true = luôn dùng AdMob Test Ad Unit ID, bất kể id
    ///thật lấy được từ Firebase Remote Config/server) ngay lúc init, thay
    ///vì phải tự gọi CallApi.instance.isUsingIdDebug = ... riêng. Bỏ trống
    ///(null) thì giữ nguyên giá trị hiện tại (mặc định true).
    bool? isUsingIdDebug,
  }) {
    if (isUsingIdDebug != null) {
      CallApi.instance.isUsingIdDebug = isUsingIdDebug;
    }
    return SplashAdsController.instance.init(
      linkServer: linkServer,
      appId: appId,
      packageName: packageName,
      jsonIdAdsDefault: jsonIdAdsDefault,
      navigatorKey: navigatorKey,
      nameIddAdsResume: nameIddAdsResume,
      nameResumeConfig: nameResumeConfig,
      nameIdAdsInterSplash: nameIdAdsInterSplash,
      nameIdAdsNativeAfterInter: nameIdAdsNativeAfterInter,
      nameConfigInterSplash: nameConfigInterSplash,
      nameConfigNativeAfterInter: nameConfigNativeAfterInter,
      nameIntervalBetweenInter: nameIntervalBetweenInter,
      nameIntervalFromStart: nameIntervalFromStart,
      nameIntervalInterAll: nameIntervalInterAll,
      isShowWelComeScreenAfterAppOpenAds: isShowWelComeScreenAfterAppOpenAds,
      onGotoScreenWelcomeBack: onGotoScreenWelcomeBack,
      onNext: onNext,
      onStartLoadBanner: onStartLoadBanner,
      remoteConfigKeys: remoteConfigKeys,
      eventAdjustTracking: eventAdjustTracking,
    );
  }

  Future<void> logEventSplashToStep({
    required String nameEvent,
    Map<String, Object>? moreParams,
  }) {
    return SplashAdsController.instance.logEventSplashToStep(
      nameEvent: nameEvent,
      moreParams: moreParams,
    );
  }

  Future<void> fetchUMP(
    Future callIdAdsDone, {
    required GlobalKey<NavigatorState> navigatorKey,
    required String nameIdAdsResume,
    required String nameResumeConfig,
    required bool isShowWelComeScreenAfterAppOpenAds,
    Function()? onGotoScreenWelcomeBack,
    required String nameIdAdsInterSplash,
    String? nameIdNativeAfterInter,
    required String nameConfigInterSplash,
    String? nameConfigNativeAfterInter,
    required Function() onNext,
    required String nameIntervalBetweenInter,
    required String nameIntervalFromStart,
    required String nameIntervalInterAll,
    required Function() onStartLoadBanner,
  }) {
    return SplashAdsController.instance.fetchUMP(
      callIdAdsDone,
      navigatorKey: navigatorKey,
      nameIdAdsResume: nameIdAdsResume,
      nameResumeConfig: nameResumeConfig,
      isShowWelComeScreenAfterAppOpenAds: isShowWelComeScreenAfterAppOpenAds,
      onGotoScreenWelcomeBack: onGotoScreenWelcomeBack,
      nameIdAdsInterSplash: nameIdAdsInterSplash,
      nameIdNativeAfterInter: nameIdNativeAfterInter,
      nameConfigInterSplash: nameConfigInterSplash,
      nameConfigNativeAfterInter: nameConfigNativeAfterInter,
      onNext: onNext,
      nameIntervalBetweenInter: nameIntervalBetweenInter,
      nameIntervalFromStart: nameIntervalFromStart,
      nameIntervalInterAll: nameIntervalInterAll,
      onStartLoadBanner: onStartLoadBanner,
    );
  }

  Future<void> fetchRemoteFirebase({required List<RemoteConfigKey> remoteConfigKeys}) {
    return SplashAdsController.instance.fetchRemoteFirebase(remoteConfigKeys: remoteConfigKeys);
  }

  Future<void> fetchApiAds({
    required String linkServer,
    required String appId,
    required String packageName,
    required Function() onResponse,
    required Function(String) onError,
  }) {
    return SplashAdsController.instance.fetchApiAds(
      linkServer: linkServer,
      appId: appId,
      packageName: packageName,
      onResponse: onResponse,
      onError: onError,
    );
  }

  Future<void> initAndShowAdSplash({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAdsAppOpen,
    required String idAdsInter,
    String? adsKeyNativeAfterInter,
    required bool configAppOpen,
    required bool configInter,
    String? remoteKeyNativeAfterInter,
    required String rateAoa,
    required Function() onNext,
  }) {
    return SplashAdsController.instance.initAndShowAdSplash(
      navigatorKey: navigatorKey,
      idAdsInter: idAdsInter,
      adsKeyNativeAfterInter: adsKeyNativeAfterInter,
      configInter: configInter,
      remoteKeyNativeAfterInter: remoteKeyNativeAfterInter,
      onNext: onNext,
    );
  }

  ///show cho trường hợp bị timeout id ads splash => thuong se show tai nut tick man Language
  Future<void> showAdsSplash({
    required GlobalKey<NavigatorState> navigatorKey,
    required Function() onNext,
  }) {
    return SplashAdsController.instance.showAdsSplash(navigatorKey: navigatorKey, onNext: onNext);
  }

  Future<void> startShowNativeAfterInter({
    required BuildContext context,
    required String adsKey,
    required String remoteKey,
    required Function() onClose,
  }) {
    return NativeAfterInterHandler.instance.startShowNativeAfterInter(
      context: context,
      adsKey: adsKey,
      remoteKey: remoteKey,
      onClose: onClose,
    );
  }

  Future<void> preloadNativeAfterInter({
    required String adsKey,
    required String remoteKey,
    String? factoryId,
  }) {
    return NativeAfterInterHandler.instance.preloadNativeAfterInter(
      adsKey: adsKey,
      remoteKey: remoteKey,
      factoryId: factoryId,
    );
  }

  ///===================== hết phần Splash / init flow =====================

  // Future<void> initAdmob() async {
  //   MobileAds.instance.initialize();
  // }
  Future<void> initAdmob() async {
    // if (_isAdmobInitialized) {
    //   return;
    // }
    //
    // MobileAds.instance.initialize().then((value) {
    //   print("=== Mediation AdMob Initialization Status ===");
    //   value.adapterStatuses.forEach((key, status) {
    //     final state = status.state;
    //     final description = status.description;
    //
    //     print("  Adapter: $key");
    //     print("  State: $state");
    //     print("  Description: $description");
    //
    //     if (state == AdapterInitializationState.notReady) {
    //       print("  ⚠️ This adapter is NOT READY. Check SDK setup, app ID, or initialization code.");
    //     } else if (state == AdapterInitializationState.ready) {
    //       print("  ✅ Ready to serve ads.");
    //     }
    //   });
    //   print("=== End of Adapter Status ===");
    // });
    //
    // _isAdmobInitialized = true;
  }

  Future<void> openMediationTest() async {}

  Future<String?> getPlatformVersion() {
    return AdmobPlatformService.instance.getPlatformVersion();
  }

  Future<bool?> getConsentResult() {
    return AdmobPlatformService.instance.getConsentResult();
  }

  Future<bool?> isNetworkActive() {
    return AdmobPlatformService.instance.isNetworkActive();
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
    Function(String)? onAdFailedToLoad,
    Function(String)? onAdFailedToShow,
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
        onAdFailedToShow: (error) {
          if (isInterAll == true) {
            AdHelper.isFirstShowInterAll = true;
          }
          onAdFailedToShow?.call();
        },
        onAdFailedToLoad: (error) {
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

  //Inter ad preloading
  Future<void> loadInterAdPreload({
    required String idAds,
    required String nameConfig,
    Function()? onAdLoaded,
    Function(String)? onAdFailedToLoad,
  }) async {
    InterAdsManager.instance.loadInterAdPreload(
      idAds: idAds,
      nameConfig: nameConfig,
      onAdLoaded: onAdLoaded,
      onAdFailedToLoad: onAdFailedToLoad,
    );
  }

  Future<void> showInterAdPreload({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    required bool isInterAll,
    required Function() onNext,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function(String)? onAdFailedToShow,
    Function()? onAdDismiss,
    required String name,
    bool isShowLoading = true,
  }) async {
    if (AdHelper.canShowNextInter(isInterAll: isInterAll)) {
      print(
        'admob_ads --- Inter Ad Preload: canShowNextInter = ${AdHelper.canShowNextInter(isInterAll: isInterAll)}',
      );
      InterAdsManager.instance.showInterAdPreload(
        navigatorKey: navigatorKey,
        idAds: idAds,
        config: config,
        onNext: onNext,
        onAdImpression: onAdImpression,
        onAdClicked: onAdClicked,
        onAdFailedToShow: onAdFailedToShow,
        onAdDismiss: onAdDismiss,
        name: name,
        isShowLoading: isShowLoading,
      );
    } else {
      print(
        'admob_ads --- Inter Ad Preload: not canShowNextInter = ${AdHelper.canShowNextInter(isInterAll: isInterAll)}',
      );
      onNext();
    }
  }

  Future<void> loadAndShowInterAdPreload({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    required bool isInterAll,
    required Function() onNext,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function(String)? onAdFailedToShow,
    Function()? onAdDismiss,
    Function()? onAdLoaded,
    Function(String)? onAdFailedToLoad,
    required String name,
  }) async {
    if (AdHelper.canShowNextInter(isInterAll: isInterAll)) {
      InterAdsManager.instance.loadAndShowInterAdPreload(
        navigatorKey: navigatorKey,
        idAds: idAds,
        config: config,
        onNext: onNext,
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdImpression: onAdImpression,
        onAdClicked: onAdClicked,
        onAdFailedToShow: onAdFailedToShow,
        onAdDismiss: onAdDismiss,
        name: name,
      );
    } else {
      onNext();
    }
  }

  Future<void> loadRewardAdPreload({
    required String idAds,
    required bool config,
    Function()? onAdLoaded,
    Function()? onAdFailedToLoad,
  }) async {
    RewardAdManager.instance.loadRewardAdPreload(
      idAds: idAds,
      config: config,
      onAdLoaded: onAdLoaded,
      onAdFailedToLoad: onAdFailedToLoad,
    );
  }

  Future<void> showRewardAdPreload({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    required Function() onNext,
    required Function() onUserEarnedReward,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function()? onAdFailedToShow,
    Function()? onAdDismiss,
    required String name,
    bool isShowLoading = true,
  }) async {
    RewardAdManager.instance.showRewardAdPreload(
      navigatorKey: navigatorKey,
      idAds: idAds,
      config: config,
      onNext: onNext,
      onUserEarnedReward: onUserEarnedReward,
      name: name,
    );
  }

  Future<void> loadAndShowRewardAdPreload({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAds,
    required bool config,
    required Function() onNext,
    required Function() onUserEarnedReward,
    Function()? onAdLoaded,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function()? onAdFailedToLoad,
    Function()? onAdFailedToShow,
    Function()? onAdDismiss,
    required String name,
  }) async {
    RewardAdManager.instance.loadAndShowRewardAdPreload(
      navigatorKey: navigatorKey,
      idAds: idAds,
      config: config,
      onNext: onNext,
      onUserEarnedReward: onUserEarnedReward,
      name: name,
    );
  }
}
