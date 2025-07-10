import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppLifecycleReactor {
  GlobalKey<NavigatorState> navigatorKey;
  String idAds;
  final bool
  isShowWelComeScreenAfterAppOpenAds; // false - show WelcomeBackScreen truoc ads, true - show WelcomeBack sau ads
  bool config;
  Function()? onGotoWelcomeBack;

  AppLifecycleReactor({
    required this.navigatorKey,
    required this.idAds,
    required this.config,
    required this.isShowWelComeScreenAfterAppOpenAds,
    this.onGotoWelcomeBack,
  });

  bool isDisableAdResume = false; // an resume khi click share, hay permisison
  bool isShowScreenWelcomeBack = false; // check Screen WelcomeBack show hay k show
  bool _onSplashScreen = true; // Screen Splash not show app open

  setOnSplashScreen({required bool value}) {
    _onSplashScreen = value;
  }

  setDisableAdResume({required bool value}) {
    isDisableAdResume = value;
  }

  void listenToAppStateChanges() {
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.forEach((state) => _onAppStateChanged(state));
  }

  setShowScreenWelcomeBack() {
    if (onGotoWelcomeBack != null) {
      if (isShowScreenWelcomeBack == false) {
        print('admob_ads --- app_open: show screen welcomeback');
        isShowScreenWelcomeBack = true;
        onGotoWelcomeBack!();
      }
    }
  }

  void _onAppStateChanged(AppState appState) async {
    if (_onSplashScreen) return;
    print('admob_ads --- app_open: start');
    if (config == false) {
      print('admob_ads --- app_open: config = $config');
      setShowScreenWelcomeBack();
      return;
    }

    if (appState == AppState.foreground) {
      if (isDisableAdResume == false) {
        if (Admob.instance.isFullScreenAdShowing == true ||
            Admob.instance.isShowAllAds == false ||
            (await Admob.instance.isNetworkActive()) == false ||
            ConsentManager.instance.canRequestAds == false) {
          print('admob_ads --- app_open: not show');
          return;
        }
        if (isShowWelComeScreenAfterAppOpenAds) {
          print('admob_ads --- app_open: show ads before screen welcomeback');
          Admob.instance.loadAndShowAppOpenAds(
            navigatorKey: navigatorKey,
            idAds: idAds,
            config: config,
            onAdDismiss: () {
              setShowScreenWelcomeBack();
            },
            onAdFailedToLoad: () {
              setShowScreenWelcomeBack();
            },
            onAdFailedToShow: () {
              setShowScreenWelcomeBack();
            },
            onAdDisable: () {
              setShowScreenWelcomeBack();
            },
          );
        } else {
          print('admob_ads --- app_open: show welcomeback before ads');
          setShowScreenWelcomeBack();
        }
      } else {
        print('admob_ads --- app_open: disable ads resume');
        isDisableAdResume = false;
      }
    }
  }

  loadAndShowAppOpenAds({
    required Function() onAdDisable,
    required Function() onAdFailedToLoad,
    required Function() onAdFailedToShow,
    required Function() onAdDismiss,
  }) {
    if (isShowWelComeScreenAfterAppOpenAds == false) {
      Admob.instance.loadAndShowAppOpenAds(
        navigatorKey: navigatorKey,
        idAds: idAds,
        config: config,
        onAdDismiss: () {
          isShowScreenWelcomeBack = false;
          onAdDismiss.call();
        },
        onAdFailedToLoad: () {
          isShowScreenWelcomeBack = false;
          onAdFailedToLoad.call();
        },
        onAdFailedToShow: () {
          isShowScreenWelcomeBack = false;
          onAdFailedToShow.call();
        },
        onAdDisable: () {
          isShowScreenWelcomeBack = false;
          onAdDisable.call();
        },
      );
    } else {
      isShowScreenWelcomeBack = false;
      onAdDisable.call();
    }
  }
}
