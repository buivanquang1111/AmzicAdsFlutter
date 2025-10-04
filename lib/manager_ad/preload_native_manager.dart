import 'dart:async';

import 'package:amazic_ads_flutter/shimmer/shimmer_native_ads.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../admob.dart';
import '../ump/consent_manager.dart';

class NativeAdManager {
  static final NativeAdManager _instance = NativeAdManager._internal();

  factory NativeAdManager() => _instance;

  NativeAdManager._internal();

  /// Map lưu trữ quảng cáo
  final Map<String, NativeAd?> _adsCache = {};

  // --- StreamController để thông báo sự kiện
  final Map<String, StreamController<bool>> _loadingStateControllers = {};

  // Tạo stream controller cho từng name ID ads (key)
  Stream<bool> getLoadingStream(String nameIdAds) {
    if (!_loadingStateControllers.containsKey(nameIdAds)) {
      _loadingStateControllers[nameIdAds] = StreamController<bool>.broadcast(sync: true);
    }
    return _loadingStateControllers[nameIdAds]!.stream;
  }

  //Sink báo hiệu sự kiện loading
  Sink<bool> getLoadingSink(String nameIdAds) {
    if (!_loadingStateControllers.containsKey(nameIdAds)) {
      _loadingStateControllers[nameIdAds] = StreamController<bool>.broadcast(sync: true);
    }
    return _loadingStateControllers[nameIdAds]!.sink;
  }

  // --- preloadAd (Gần như giữ nguyên) ---
  Future<void> preloadAd({
    required String adUnitId,
    required bool config,
    required String nameIdAds,
    required String factoryId,
    Function()? onAdLoaded,
    Function(String)? onAdFailed,
  }) async {
    print('preload_native --- start load ads');
    if(!await canShowAds(config: config)){
      print('preload_native --- canShowAds = false => not preload ads $nameIdAds');
      return;
    }

    getLoadingSink(nameIdAds).add(true); // Báo loading bắt đầu

    // (Giữ nguyên logic loadAd cũ)...
    NativeAd ad = NativeAd(
      adUnitId: adUnitId,
      factoryId: factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('preload_native --- load xong');
          _adsCache[nameIdAds] = ad as NativeAd;
          getLoadingSink(nameIdAds).add(false); // Báo loading kết thúc
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          print('preload_native --- load false');
          _adsCache[nameIdAds] = null;
          getLoadingSink(nameIdAds).add(false); // Báo loading kết thúc (dù lỗi)
          onAdFailed?.call(error.message);
        },
      ),
    );
    ad.load();
  }

  Future<bool> canShowAds({required bool config}) async {
    return config &&
        ConsentManager.instance.canRequestAds &&
        Admob.instance.isShowAllAds &&
        (await Admob.instance.isNetworkActive()) == true;
  }

  // --- showAd (ĐÃ THAY ĐỔI) ---
  /// [nameIdAds]: ID dùng khi preload.
  Widget showAd({
    required bool config,
    required String nameIdAds,
    required double height,
    Widget? shimmer,
    Widget? placeholder,
  }) {
    print('preload_native --- start show');

    if (!_loadingStateControllers.containsKey(nameIdAds)) {
      print('preload_native --- Error: $nameIdAds không tồn tại, config = $config');
      return placeholder ?? const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: canShowAds(config: config),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          print('preload_native --- await canShowAds chua xong');
          return placeholder ?? const SizedBox.shrink();
        } else if (snapshot.hasData && snapshot.data == true) {
          return StreamBuilder<bool>(
            stream: getLoadingStream(nameIdAds), // Lắng nghe stream loading
            initialData: !isAdReady(nameIdAds),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                print('preload_native --- shimmer');
                // Đang loading -> Hiển thị loading indicator
                return shimmer ?? ShimmerNativeAds(height: height);
              } else {
                // Không loading nữa -> Xem có quảng cáo chưa
                final ad = _adsCache[nameIdAds];
                if (ad != null) {
                  print('preload_native --- show ads');
                  // Có quảng cáo -> Hiển thị AdWidget
                  return SizedBox(
                    height: height,
                    width: double.infinity,
                    child: AdWidget(ad: ad),
                  );
                } else {
                  print('preload_native --- not show');
                  // Không có quảng cáo (lỗi hoặc chưa load) -> Hiển thị placeholder
                  return placeholder ?? const SizedBox.shrink(); // Ẩn hoặc widget mặc định
                }
              }
            },
          );
        } else {
          print(
            'preload_native --- canShowAds: config = $config,  ump = ${ConsentManager.instance.canRequestAds}, isShowAllAds = ${Admob.instance.isShowAllAds}, ',
          );
          return const SizedBox.shrink();
        }
      },
    );
  }

  // --- Các hàm tiện ích (dispose) ---
  void disposeAd(String nameIdAds) {
    _adsCache[nameIdAds]?.dispose();
    _adsCache.remove(nameIdAds);
    _loadingStateControllers[nameIdAds]?.close();
    _loadingStateControllers.remove(nameIdAds);
  }

  bool isAdReady(String nameIdAds) {
    return _adsCache.containsKey(nameIdAds) && _adsCache[nameIdAds] != null;
  }

  void disposeAll() {
    _adsCache.forEach((key, value) {
      value?.dispose();
    });
    _adsCache.clear();

    _loadingStateControllers.forEach((key, value) {
      value.close(); // Đóng tất cả StreamController khi disposeAll
    });
    _loadingStateControllers.clear();
  }
}
