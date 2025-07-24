import 'dart:ui';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ump/consent_manager.dart';
import '../utils/adjust_util.dart';
import '../utils/event_log.dart';
import '../utils/utils.dart';

class RewardAdManager {
  RewardAdManager._();

  static final RewardAdManager instance = RewardAdManager._();

  ///reward load and show 2 hay nhieu reward cung luc
  final Map<String, RewardedAd?> rewardAds = {};

  loadRewardAdConsecutive({required String idAds, required bool config}) {
    if (rewardAds[idAds] == null) {
      loadRewardAd(
        idAds: idAds,
        config: config,
        onAdLoaded: (ad) {
          rewardAds[idAds] = ad;
        },
        onAdFailedToLoad: () {
          rewardAds[idAds] = null;
        },
      );
    } else {
      print('admob_ads --- reward_ads - load_before: Reward have != null');
    }
  }

  showRewardAdConsecutive({
    required String idAds,
    required bool config,
    bool isLoadAdsBeforeNext = false,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function()? onAdFailedToShow,
    Function()? onAdDismiss,
    Function()? onUserEarnedReward,
    required String name,
  }) {
    showRewardAd(
      rewardedAd: rewardAds[idAds],
      config: config,
      onAdImpression: () {
        onAdImpression?.call();
      },
      onAdClicked: () {
        onAdClicked?.call();
      },
      onAdFailedToShow: () {
        onAdFailedToShow?.call();
      },
      onAdDismiss: () {
        onAdDismiss?.call();
      },
      onUserEarnedReward: () {
        onUserEarnedReward?.call();
      },
      name: name
    );
    rewardAds[idAds] = null;
    if (isLoadAdsBeforeNext == true) {
      loadRewardAdConsecutive(idAds: idAds, config: config);
    }
  }

  showRewardConsecutive({
    required String idAds,
    required bool config,
    required int count,
    required VoidCallback onCompleted,
    required String name,
  }) {
    int current = 0;
    bool isRewardEarned =
        false; // check user da thuc su xem het ads chua, neu xem chua het ma dismiss thi khong tinh 1 lan
    void showRewardNext() {
      if (current >= count) {
        onCompleted();
        return;
      }

      isRewardEarned = false;

      //se bi thua 1 lan request ads truoc ve sau co the can nhac sua
      showRewardAdConsecutive(
        idAds: idAds,
        config: config,
        isLoadAdsBeforeNext: true,
        name: name,
        onUserEarnedReward: () {
          isRewardEarned = true;
          print(
            'admob_ads --- reward_ads - load_before: onUserEarnedReward user xem xong lan ${current + 1}',
          );
        },
        onAdDismiss: () {
          if (isRewardEarned) {
            current++;
            print(
              'admob_ads --- reward_ads - load_before: onAdDismiss da hoan thanh 1 lan xem reward',
            );
          } else {
            print(
              'admob_ads --- reward_ads - load_before: onAdDismiss User chua xem het ads -> khong tinh',
            );
          }
          showRewardNext();
        },
        onAdFailedToShow: () {
          //false thi se load cai khac phai show du count reward moi xong
          print(
            'admob_ads --- reward_ads - load_before: onAdFailedToShow error khong show ads -> khong tinh',
          );
          showRewardNext();
        },
      );
    }

    showRewardNext();
  }
  ///end

  ///load ads
  Future<void> loadRewardAd({
    required String idAds,
    required bool config,
    required Function(RewardedAd) onAdLoaded,
    required Function() onAdFailedToLoad,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
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

  ///show ads
  Future<void> showRewardAd({
    required RewardedAd? rewardedAd,
    required bool config,
    required Function() onAdImpression,
    required Function() onAdClicked,
    required Function() onAdFailedToShow,
    required Function() onAdDismiss,
    required Function() onUserEarnedReward,
    required String name,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
      print('admob_ads --- reward_ads - load_before: not show');
      return;
    }
    if (rewardedAd != null) {
      rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdImpression: (ad) {
          print('admob_ads --- reward_ads - load_before: onAdImpression');
          onAdImpression.call();
          EventLog.logEvent('${name}_view');
        },
        onAdClicked: (ad) {
          print('admob_ads --- reward_ads - load_before: onAdClicked');
          onAdClicked.call();
          EventLog.logEvent('${name}_click');
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

  ///load and show
  Future<void> loadAndShowRewardAds({
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
    required Function()? onUserEarnedReward,
    required String name,
  }) async {
    if (config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
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
              Admob.instance.setFullScreenAdShowing(true);
              onAdImpression?.call();
              EventLog.logEvent('${name}_view');
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('admob_ads --- reward_ads: onAdFailedToShowFullScreenContent');
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              Admob.instance.setFullScreenAdShowing(false);
              ad.dispose();
              onAdFailedToShow?.call();
            },
            onAdDismissedFullScreenContent: (ad) {
              print('admob_ads --- reward_ads: onAdDismissedFullScreenContent');
              if (navigatorKey.currentContext != null) {
                closeLoadingDialog(context: navigatorKey.currentContext!);
              }
              Admob.instance.setFullScreenAdShowing(false);
              ad.dispose();
              onAdDismiss?.call();
            },
            onAdClicked: (ad) {
              print('admob_ads --- reward_ads: onAdClicked');
              onAdClicked?.call();
              EventLog.logEvent('${name}_click');
            },
          );
          Admob.instance.setFullScreenAdShowing(true);
          Admob.instance.checkAndShowAdForeground(
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
