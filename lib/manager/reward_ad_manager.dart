import 'dart:ui';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardAdManager {
  RewardAdManager._();

  static final RewardAdManager instance = RewardAdManager._();

  final Map<String, RewardedAd?> rewardAds = {};

  loadRewardAd({required String idAds, required bool config}) {
    if (rewardAds[idAds] == null) {
      Admob.instance.loadRewardAd(
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

  showRewardAd({
    required String idAds,
    required bool config,
    bool isLoadAdsBeforeNext = false,
    Function()? onAdImpression,
    Function()? onAdClicked,
    Function()? onAdFailedToShow,
    Function()? onAdDismiss,
    Function()? onUserEarnedReward,
  }) {
    Admob.instance.showRewardAd(
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
    );
    rewardAds[idAds] = null;
    if (isLoadAdsBeforeNext == true) {
      loadRewardAd(idAds: idAds, config: config);
    }
  }

  showRewardConsecutive({
    required String idAds,
    required bool config,
    required int count,
    required VoidCallback onCompleted,
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
      showRewardAd(
        idAds: idAds,
        config: config,
        isLoadAdsBeforeNext: true,
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
}
