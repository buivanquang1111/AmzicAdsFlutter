import 'dart:async';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/call_api/call_api.dart';
import 'package:amazic_ads_flutter/manager_ad/app_open_manager.dart';
import 'package:amazic_ads_flutter/manager_ad/inter_ads_manager.dart';
import 'package:amazic_ads_flutter/splash_ads/native_after_inter_handler.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:amazic_ads_flutter/utils/ad_helper.dart';
import 'package:amazic_ads_flutter/utils/app_lifecycle_reactor.dart';
import 'package:amazic_ads_flutter/utils/event_log.dart';
import 'package:amazic_ads_flutter/utils/preferences_util.dart';
import 'package:amazic_ads_flutter/utils/remote_config.dart';
import 'package:flutter/material.dart';

/// Toàn bộ luồng khởi tạo quảng cáo ở màn Splash: gọi song song Firebase
/// Remote Config, UMP consent và API lấy id quảng cáo, sau đó quyết định
/// show App Open Ad hay Interstitial Ad ở splash.
///
/// Được tách ra khỏi [Admob] vì đây là phần logic dài và phức tạp nhất của
/// thư viện. [Admob] chỉ đóng vai trò facade: mọi lời gọi
/// `Admob.instance.init(...)`, `Admob.instance.logEventSplashToStep(...)`,
/// `Admob.instance.showAdsSplash(...)` ... đều được forward xuống đây,
/// nên phía app dùng thư viện không cần thay đổi gì cả.
class SplashAdsController {
  SplashAdsController._();

  static final SplashAdsController instance = SplashAdsController._();

  ///đếm thời gian từ lúc vào màn đến khi show ads splash
  final Stopwatch stopWatch = Stopwatch();

  ///timeout check 12s
  bool isNextTimeout = false; // biến check xem đã chuyển màn trong timeout splash
  bool isTimeoutSplash = false;
  final Completer<void> timeoutSplashCompleter = Completer<void>();

  ///thời gian (giây, tính theo stopWatch.elapsed - KHÔNG dùng DateTime.now().second
  ///vì .second chỉ là giây trong 1 phút (0-59), bị quay vòng ("wrap") mỗi khi
  ///qua mốc phút => tính hiệu số ra âm) tại lúc log event ở bước ngay trước.
  int _lastStepElapsedSeconds = 0;

  void handleTimeOut() {
    if (!isTimeoutSplash) {
      isTimeoutSplash = true;
      print(
        'admob_ads --- kết thúc bỏ qua check timeout Screen Splash ${Admob.instance.timeoutScreenSplash}s',
      );
      if (!timeoutSplashCompleter.isCompleted) timeoutSplashCompleter.complete();
    }
  }

  ///Đã bỏ hẳn nameIdAdsAppOpenSplash/nameConfigAppOpenSplash/nameRateAoa -
  ///không còn dùng App Open Splash / rateAoa để quyết định show ads splash
  ///nữa (xem initAndShowAdSplash).
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
  }) async {
    ///start count time show ads
    stopWatch.start();
    _lastStepElapsedSeconds = 0;

    ///set json id default
    Admob.instance.setJsonIdAdsDefault(jsonIdAdsDefault);

    await Future.wait([
      Admob.instance.isNetworkActive().then((hasNet) {
        if (hasNet == true) EventLog.logEvent('splash_open_have_internet');
      }),
      PreferencesUtil.init().then((value) {
        PreferencesUtil.increaseCountOpenApp();
      }),
    ]);

    ///set event adjust
    if (eventAdjustTracking != null) {
      Admob.instance.setEventTrackingAdjust(eventAdjustTracking);
    }

    ///call dong thoi task
    ///id quảng cáo giờ lấy từ Firebase Remote Config (xem fetchRemoteFirebase
    ///-> RemoteConfig.init -> CallApi.setIdFromRemoteConfig), nên không cần
    ///gọi callIDAdsTask (API lấy id từ server) trong luồng init nữa. Code
    ///lấy id từ server (fetchApiAds/CallApi.callAds) vẫn được giữ nguyên,
    ///chỉ là không cần dùng ở đây.
    late Future<void> firebaseTask;
    late Future<void> umpTask;

    firebaseTask = fetchRemoteFirebase(remoteConfigKeys: remoteConfigKeys);
    umpTask = fetchUMP(
      firebaseTask,
      navigatorKey: navigatorKey,
      nameIdAdsResume: nameIddAdsResume,
      nameResumeConfig: nameResumeConfig,
      isShowWelComeScreenAfterAppOpenAds: isShowWelComeScreenAfterAppOpenAds,
      nameIdAdsInterSplash: nameIdAdsInterSplash,
      nameIdNativeAfterInter: nameIdAdsNativeAfterInter,
      nameConfigInterSplash: nameConfigInterSplash,
      nameConfigNativeAfterInter: nameConfigNativeAfterInter,
      onNext: onNext,
      nameIntervalBetweenInter: nameIntervalBetweenInter,
      nameIntervalFromStart: nameIntervalFromStart,
      nameIntervalInterAll: nameIntervalInterAll,
      onStartLoadBanner: onStartLoadBanner,
      onGotoScreenWelcomeBack: onGotoScreenWelcomeBack,
    );

    final Map<String, Future<void>> tasks = {
      'FIREBASE_REMOTE': firebaseTask,
      'UMP': umpTask,
    };

    EventLog.logEvent('splash_async_init');
    // Đánh dấu tiến trình đã hoàn thành hay chưa
    final Map<String, bool> taskCompleted = {
      'FIREBASE_REMOTE': false,
      'UMP': false,
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

    // Đợi timeoutScreenSplash giây (mặc định 20s)
    final timeoutSeconds = Admob.instance.timeoutScreenSplash;
    await Future.delayed(Duration(seconds: timeoutSeconds), () {
      if (!isTimeoutSplash) {
        print('admob_ads --- Timeout Splash ${timeoutSeconds}s');
        EventLog.logEvent('timeout_splash', parameters: {'timeout_seconds': timeoutSeconds});
        timeoutSplashCompleter.complete();
        isTimeoutSplash = true;
        isNextTimeout = true;
        onNext();
        print('admob_ads --- onNext Timeout Splash ${timeoutSeconds}s');
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
      final secondsShowAds = stopWatch.elapsed.inSeconds;
      print('admob_ads --- 🎉 Tất cả task đã hoàn thành trong vòng $secondsShowAds giây');
    }
  }

  Future<void> logEventSplashToStep({
    required String nameEvent,
    Map<String, Object>? moreParams,
  }) async {
    ///tổng số giây từ lúc bắt đầu init() (stopWatch.start()) đến bước này
    final currentElapsedSeconds = stopWatch.elapsed.inSeconds;
    final timeToStep = currentElapsedSeconds;
    ///số giây từ bước log event ngay trước đó đến bước này
    final timeBetweenStep = currentElapsedSeconds - _lastStepElapsedSeconds;
    final Map<String, Object> fullParams = {
      "time_to_step": timeToStep,
      "time_between_step": timeBetweenStep,
      if (moreParams != null) ...moreParams,
    };
    EventLog.logEvent(nameEvent, parameters: fullParams);
    print('admob_ads --- $nameEvent - parameters = $fullParams');
    _lastStepElapsedSeconds = currentElapsedSeconds;
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
  }) async {
    logEventSplashToStep(nameEvent: 'splash_start_ump');
    //init UMP
    await ConsentManager.instance.handleRequestUmp(
      onPostExecute: () async {
        if (ConsentManager.instance.canRequestAds) {
          logEventSplashToStep(nameEvent: 'splash_ump_done_consent');
          print('admob_ads --- ✅ Done UMP, await call id ads');
          await callIdAdsDone;
          print('admob_ads --- 🚀 Continue process show ads splash');

          ///preload native after inter
          if (nameIdNativeAfterInter != null && nameConfigNativeAfterInter != null) {
            NativeAfterInterHandler.instance.preloadNativeAfterInter(
              adsKey: nameIdNativeAfterInter,
              remoteKey: nameConfigNativeAfterInter,
            );
          }

          onStartLoadBanner();
          logEventSplashToStep(nameEvent: 'splash_init_ad_splash');

          ///init app open resume
          ///Luôn khởi tạo dù splash có bị timeout hay không, để App Open Ad
          ///lúc resume app vẫn hoạt động bình thường ở các màn sau.
          Admob.instance.appLifecycleReactor = AppLifecycleReactor(
            navigatorKey: navigatorKey,
            idAds: CallApi.instance.getFirstIDByName(nameIdAdsResume),
            nameResumeConfig: nameResumeConfig,
            isShowWelComeScreenAfterAppOpenAds: isShowWelComeScreenAfterAppOpenAds,
            onGotoWelcomeBack: onGotoScreenWelcomeBack,
            name: nameIdAdsResume,
          );
          Admob.instance.appLifecycleReactor?.listenToAppStateChanges();

          ///init ads splash
          ///Luôn gọi dù splash có bị timeout hay không: AdHelper.init set
          ///mốc thời gian bắt đầu app, nếu bỏ qua thì AdHelper.canShowNextInter
          ///sẽ luôn trả về false => toàn bộ Interstitial Ad ở các màn sau
          ///cũng sẽ không hiện được nữa trong suốt session.
          ///configAppOpen/rateAoa không còn cần khởi tạo ở đây nữa vì
          ///AdHelper.splashType (dùng open/inter theo rateAoa) không còn
          ///được gọi trong initAndShowAdSplash - mặc định chỉ show
          ///Interstitial. AdHelper.init đã có default cho 2 giá trị này.
          AdHelper.init(
            intervalBetweenInter: RemoteConfig.getInt(nameIntervalBetweenInter) * 1000,
            intervalFromStart: RemoteConfig.getInt(nameIntervalFromStart) * 1000,
            intervalInterAll: RemoteConfig.getInt(nameIntervalInterAll) * 1000,
            configInter: RemoteConfig.getBool(nameConfigInterSplash),
          );

          ///đã timeout splash rồi (đã chuyển màn) => không show ads splash / gọi
          ///onNext lần nữa. Các bước setup dùng chung ở trên vẫn đã chạy xong.
          if (isNextTimeout) {
            print(
              'admob_ads --- ⏭️ Đã timeout splash trước đó, bỏ qua bước show ads splash (đã qua màn rồi)',
            );
            return;
          }
          handleTimeOut();

          initAndShowAdSplash(
            navigatorKey: navigatorKey,
            idAdsInter: CallApi.instance.getFirstIDByName(nameIdAdsInterSplash),
            adsKeyNativeAfterInter: nameIdNativeAfterInter,
            configInter: RemoteConfig.getBool(nameConfigInterSplash),
            remoteKeyNativeAfterInter: nameConfigNativeAfterInter,
            onNext: onNext,
          );
        } else {
          handleTimeOut();
          if (!isNextTimeout) {
            print('admob_ads --- onNext DO NOT CONSENT');
            logEventSplashToStep(nameEvent: 'splash_ump_done_donotconsent');
            onNext();
          }
        }
      },
    );
  }

  Future<void> fetchRemoteFirebase({required List<RemoteConfigKey> remoteConfigKeys}) async {
    logEventSplashToStep(nameEvent: 'splash_start_firebase');
    await RemoteConfig.init(remoteConfigKeys: remoteConfigKeys);

    ///Sau khi lấy id quảng cáo từ Remote Config (RemoteConfig.init đã gọi
    ///CallApi.setIdFromRemoteConfig cho từng tên có id), fallback lấy id từ
    ///json default cho những tên chưa có id - giống bên Android
    ///(IDRemoteConfigHelper.getID() fallback qua key "_default" khi Remote
    ///Config không có). Không ghi đè id đã lấy được từ Remote Config vì
    ///convertJsonIdToList chỉ append vào cuối danh sách.
    await CallApi.instance.convertJsonIdToList(json: Admob.instance.jsonIdAdsDefault);

    logEventSplashToStep(nameEvent: 'splash_done_firebase');
  }

  Future<void> fetchApiAds({
    required String linkServer,
    required String appId,
    required String packageName,
    required Function() onResponse,
    required Function(String) onError,
  }) async {
    logEventSplashToStep(nameEvent: 'splash_start_idapi');
    await CallApi.instance.callAds(
      linkServer: linkServer,
      appId: appId,
      packageName: packageName,
      onResponse: onResponse,
      onError: onError,
    );
    logEventSplashToStep(nameEvent: 'splash_done_idapi');
  }

  Future<void> initAndShowAdSplash({
    required GlobalKey<NavigatorState> navigatorKey,
    required String idAdsInter,
    String? adsKeyNativeAfterInter,
    required bool configInter,
    String? remoteKeyNativeAfterInter,
    required Function() onNext,
  }) async {
    ///Không check AdHelper.splashType (open/inter/none) và
    ///Admob.instance.isUseAdPreloading để quyết định show App Open hay
    ///Interstitial nữa - mặc định luôn show Interstitial
    ///(InterAdsManager.loadAndShowInterSplash, bản không preload).
    ///
    ///Các luồng App Open Splash (preload/thường) và Inter Splash Preload bên
    ///dưới tạm thời không dùng nên comment lại (không xoá) để có thể bật lại
    ///sau nếu cần. Lưu ý: đoạn comment bên dưới có tham chiếu tới
    ///idAdsAppOpen/configAppOpen/rateAoa - các tham số này đã bị bỏ khỏi
    ///signature của hàm (không dùng nữa), nên nếu bật lại đoạn comment thì
    ///cần thêm lại các tham số đó.
    logEventSplashToStep(nameEvent: 'splash_ad_start_loadandshow');
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
        logEventSplashToStep(nameEvent: 'splash_ad_show');
      },
      onAdClicked: () {
        EventLog.logEvent('inter_splash_click_${PreferencesUtil.getCountOpenApp()}');
      },
      onAdDismiss: () {
        Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
        onNext();
      },
      onAdFailedToLoad: (e) {
        logEventSplashToStep(nameEvent: 'splash_ad_failload', moreParams: {'error': e});
        Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
        onNext();
      },
      onAdFailedToShow: (e) {
        logEventSplashToStep(nameEvent: 'splash_ad_failshow', moreParams: {'error': e});
        Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
        onNext();
      },
      onAdDisable: () {
        Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
        onNext();
      },
    );

    /* ============== KHÔNG DÙNG - giữ lại để bật lại sau nếu cần ==============
    if (AdHelper.splashType == AdsSplashType.open) {
      if (Admob.instance.isUseAdPreloading) {
        logEventSplashToStep(nameEvent: 'splash_ad_start_loadandshow');
        AppOpenManager.instance.loadAndShowAppOpenSplashAdPreload(
          navigatorKey: navigatorKey,
          idAds: idAdsAppOpen,
          config: configAppOpen,
          onAdDisable: () {
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            onNext();
          },
          onAdLoaded: () {},
          onAdImpression: () {
            ///stop dem time show ads
            stopWatch.stop();
            final secondsShowAds = stopWatch.elapsed.inSeconds;
            print('admob_ads --- open_splash: time show ads splash - $secondsShowAds');

            logEventSplashToStep(nameEvent: 'splash_ad_show');
          },
          onAdClicked: () {
            EventLog.logEvent('inter_splash_click_${PreferencesUtil.getCountOpenApp()}');
          },
          onAdFailedToLoad: (error) {
            logEventSplashToStep(nameEvent: 'splash_ad_failload', moreParams: {'error': error});
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            onNext();
          },
          onAdFailedToShow: (error) {
            logEventSplashToStep(nameEvent: 'splash_ad_failshow', moreParams: {'error': error});
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            onNext();
          },
          onAdDismiss: () {
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            onNext();
          },
        );
      } else {
        logEventSplashToStep(nameEvent: 'splash_ad_start_loadandshow');
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

            logEventSplashToStep(nameEvent: 'splash_ad_show');
          },
          onAdClicked: () {
            EventLog.logEvent('inter_splash_click_${PreferencesUtil.getCountOpenApp()}');
          },
          onAdFailedToLoad: (error) {
            logEventSplashToStep(nameEvent: 'splash_ad_failload', moreParams: {'error': error});
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            onNext();
          },
          onAdFailedToShow: (error) {
            logEventSplashToStep(nameEvent: 'splash_ad_failshow', moreParams: {'error': error});
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            onNext();
          },
          onAdDismiss: () {
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            onNext();
          },
        );
      }
    } else if (AdHelper.splashType == AdsSplashType.inter) {
      if (Admob.instance.isUseAdPreloading) {
        logEventSplashToStep(nameEvent: 'splash_ad_start_loadandshow');
        InterAdsManager.instance.loadAndShowInterSplashAdPreload(
          navigatorKey: navigatorKey,
          idAds: idAdsInter,
          config: configInter,
          onAdImpression: () {
            ///stop dem time show ads
            stopWatch.stop();
            final secondsShowAds = stopWatch.elapsed.inSeconds;
            print('admob_ads --- inter_splash: time show ads splash - $secondsShowAds');

            logEventSplashToStep(nameEvent: 'splash_ad_show');
          },
          onAdClicked: () {
            EventLog.logEvent('inter_splash_click_${PreferencesUtil.getCountOpenApp()}');
          },
          onAdDismiss: () {
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            NativeAfterInterHandler.instance.handleAfterInterOrNext(
              isUseNativeAfterInter: Admob.instance.isUseNativeAfterInter,
              navigatorKey: navigatorKey,
              adsKeyNativeAfterInter: adsKeyNativeAfterInter,
              remoteKeyNativeAfterInter: remoteKeyNativeAfterInter,
              onNext: onNext,
            );
          },
          onAdFailedToLoad: (error) {
            logEventSplashToStep(nameEvent: 'splash_ad_failload', moreParams: {'error': error});
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            NativeAfterInterHandler.instance.handleAfterInterOrNext(
              isUseNativeAfterInter: Admob.instance.isUseNativeAfterInter,
              navigatorKey: navigatorKey,
              adsKeyNativeAfterInter: adsKeyNativeAfterInter,
              remoteKeyNativeAfterInter: remoteKeyNativeAfterInter,
              onNext: onNext,
              debugTag: 'splash_ad_failload',
            );
          },
          onAdFailedToShow: (error) {
            logEventSplashToStep(nameEvent: 'splash_ad_failshow', moreParams: {'error': error});
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            NativeAfterInterHandler.instance.handleAfterInterOrNext(
              isUseNativeAfterInter: Admob.instance.isUseNativeAfterInter,
              navigatorKey: navigatorKey,
              adsKeyNativeAfterInter: adsKeyNativeAfterInter,
              remoteKeyNativeAfterInter: remoteKeyNativeAfterInter,
              onNext: onNext,
            );
          },
          onAdDisable: () {
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            NativeAfterInterHandler.instance.handleAfterInterOrNext(
              isUseNativeAfterInter: Admob.instance.isUseNativeAfterInter,
              navigatorKey: navigatorKey,
              adsKeyNativeAfterInter: adsKeyNativeAfterInter,
              remoteKeyNativeAfterInter: remoteKeyNativeAfterInter,
              onNext: onNext,
            );
          },
        );
      } else {
        logEventSplashToStep(nameEvent: 'splash_ad_start_loadandshow');
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
            logEventSplashToStep(nameEvent: 'splash_ad_show');
          },
          onAdClicked: () {
            EventLog.logEvent('inter_splash_click_${PreferencesUtil.getCountOpenApp()}');
          },
          onAdDismiss: () {
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            onNext();
          },
          onAdFailedToLoad: (e) {
            logEventSplashToStep(nameEvent: 'splash_ad_failload', moreParams: {'error': e});
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            onNext();
          },
          onAdFailedToShow: (e) {
            logEventSplashToStep(nameEvent: 'splash_ad_failshow', moreParams: {'error': e});
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            onNext();
          },
          onAdDisable: () {
            Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
            onNext();
          },
        );
      }
    } else {
      Admob.instance.appLifecycleReactor?.setOnSplashScreen(value: false);
      onNext();
    }
    ========================================================================== */

    ///logEvent
    ///rateAoa/configAppOpen đã bị bỏ khỏi tham số hàm (không còn dùng để
    ///show open/inter nữa) nên cũng bỏ khỏi 2 giá trị tracking bên dưới.
    final isHaveInternet = await Admob.instance.isNetworkActive();
    final ump = await Admob.instance.getConsentResult();
    EventLog.logEvent(
      'inter_splash_tracking',
      parameters: {
        'splash_detail': '${ump}_${isHaveInternet}_${Admob.instance.isShowAllAds}',
        'ump': '$ump',
        'haveinternet': '$isHaveInternet',
        'showallad': '${Admob.instance.isShowAllAds}',
        'interremote_openremote_aoavalue': '$configInter',
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
          onAdFailedToShow: (e) {
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
          onAdFailedToShow: (error) {
            onNext();
          },
          onAdDismiss: () {
            onNext();
          },
        );
      }
    }
  }
}
