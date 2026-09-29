import 'package:amazic_ads_flutter/call_api/call_api.dart';
import 'package:amazic_ads_flutter/manager_ad/preload_native_manager.dart';
import 'package:amazic_ads_flutter/utils/remote_config.dart';
import 'package:amazic_ads_flutter/view/native_after_inter_screen.dart';
import 'package:flutter/material.dart';

/// Quản lý việc preload + hiển thị Native Ad ngay sau khi Interstitial ở
/// splash bị đóng lại ("native after inter").
///
/// Class này cũng gộp lại khối điều kiện kiểm tra + quyết định
/// show/onNext vốn bị lặp lại y hệt 4 lần trong
/// `SplashAdsController.initAndShowAdSplash` (ở các callback onAdDismiss,
/// onAdFailedToLoad, onAdFailedToShow, onAdDisable của luồng Inter Splash
/// Preload) thành 1 hàm dùng chung [handleAfterInterOrNext] — hành vi và
/// log debug giữ nguyên như code gốc, chỉ bỏ trùng lặp.
class NativeAfterInterHandler {
  NativeAfterInterHandler._();

  static final NativeAfterInterHandler instance = NativeAfterInterHandler._();

  Future<void> preloadNativeAfterInter({
    required String adsKey,
    required String remoteKey,
    String? factoryId,
  }) async {
    print(
      'admob_ads --- preload_native: load $adsKey id - ${CallApi.instance.getFirstIDByName(adsKey)}',
    );
    NativeAdManager().preloadAd(
      adUnitId: CallApi.instance.getFirstIDByName(adsKey),
      config: RemoteConfig.getBool(remoteKey),
      nameIdAds: adsKey,
      factoryId: factoryId ?? 'native_after_inter',
    );
  }

  Future<void> startShowNativeAfterInter({
    required BuildContext context,
    required String adsKey,
    required String remoteKey,
    required Function() onClose,
  }) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NativeAfterInterScreen(adsKey: adsKey, remoteKey: remoteKey, onClose: onClose),
      ),
    );
  }

  /// Kiểm tra điều kiện đủ để show Native Ad ngay sau khi Interstitial ở
  /// splash đóng lại; nếu đủ điều kiện và show được thì show, ngược lại
  /// gọi [onNext] để tiếp tục luồng splash bình thường.
  ///
  /// [debugTag] chỉ dùng để giữ nguyên các dòng print debug ở nhánh
  /// onAdFailedToLoad của code gốc (các nhánh khác không truyền debugTag,
  /// giống hệt code gốc là không có print ở các nhánh đó).
  void handleAfterInterOrNext({
    required bool isUseNativeAfterInter,
    required GlobalKey<NavigatorState> navigatorKey,
    String? adsKeyNativeAfterInter,
    String? remoteKeyNativeAfterInter,
    required Function() onNext,
    String? debugTag,
  }) {
    final canUseNativeAfterInter = isUseNativeAfterInter &&
        navigatorKey.currentContext != null &&
        adsKeyNativeAfterInter != null &&
        remoteKeyNativeAfterInter != null &&
        NativeAdManager().loadingStateControllers.containsKey(adsKeyNativeAfterInter) &&
        NativeAdManager().adsCache[adsKeyNativeAfterInter] != null;

    if (debugTag != null) {
      print(
        'admob_ads --- Inter Ad Preload Splash: 1.$debugTag --- isUseNativeAfterInter = $isUseNativeAfterInter, context = ${navigatorKey.currentContext != null},'
        ' adsKeyNativeAfterInter = $adsKeyNativeAfterInter, remoteKeyNativeAfterInter = $remoteKeyNativeAfterInter, containsKey = ${adsKeyNativeAfterInter != null ? NativeAdManager().loadingStateControllers.containsKey(adsKeyNativeAfterInter) : false},'
        'adsCache = ${adsKeyNativeAfterInter != null ? NativeAdManager().adsCache[adsKeyNativeAfterInter] != null : false}',
      );
    }

    if (!canUseNativeAfterInter) {
      if (debugTag != null) {
        print('admob_ads --- Inter Ad Preload Splash: 2.$debugTag');
      }
      onNext();
      return;
    }

    final canShowNow = RemoteConfig.getBool(remoteKeyNativeAfterInter!) ||
        NativeAdManager().loadingStateControllers[adsKeyNativeAfterInter]?.sink == false;

    if (canShowNow) {
      startShowNativeAfterInter(
        context: navigatorKey.currentContext!,
        adsKey: adsKeyNativeAfterInter,
        remoteKey: remoteKeyNativeAfterInter,
        onClose: onNext,
      );
    } else {
      if (debugTag != null) {
        print(
          'admob_ads --- Inter Ad Preload Splash: 3.$debugTag --- remote = ${RemoteConfig.getBool(remoteKeyNativeAfterInter)}, sink = ${NativeAdManager().loadingStateControllers[adsKeyNativeAfterInter]?.sink == false}',
        );
      }
      onNext();
    }
  }
}
