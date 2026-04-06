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
  final Map<String, NativeAd?> adsCache = {};

  // --- StreamController để thông báo sự kiện
  final Map<String, StreamController<bool>> loadingStateControllers = {};

  // Map để lưu trữ Timer cho mỗi nameIdAds
  // final Map<String, Timer?> _preloadTimers = {};

  // Tạo stream controller cho từng name ID ads (key)
  Stream<bool> getLoadingStream(String nameIdAds) {
    if (!loadingStateControllers.containsKey(nameIdAds)) {
      loadingStateControllers[nameIdAds] = StreamController<bool>.broadcast(sync: true);
    }
    return loadingStateControllers[nameIdAds]!.stream;
  }

  //Sink báo hiệu sự kiện loading
  Sink<bool> getLoadingSink(String nameIdAds) {
    if (!loadingStateControllers.containsKey(nameIdAds)) {
      loadingStateControllers[nameIdAds] = StreamController<bool>.broadcast(sync: true);
    }
    return loadingStateControllers[nameIdAds]!.sink;
  }

  // --- preloadAd (Gần như giữ nguyên) ---
  Future<void> preloadAd({
    required String adUnitId,
    required bool config,
    required String nameIdAds,
    required String factoryId,
    // required int intervalReload,
    Function()? onAdLoaded,
    Function(String)? onAdFailed,
  }) async {
    print('preload_native --- start load $nameIdAds');
    if (!await canShowAds(config: config)) {
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
          print('preload_native --- load xong $nameIdAds');
          adsCache[nameIdAds] = ad as NativeAd;
          getLoadingSink(nameIdAds).add(false); // Báo loading kết thúc
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          print('preload_native --- load false $nameIdAds');
          adsCache[nameIdAds] = null;
          getLoadingSink(nameIdAds).add(false); // Báo loading kết thúc (dù lỗi)
          onAdFailed?.call(error.message);

          //start timer load
          // _schedulePreload(
          //   adUnitId,
          //   config,
          //   nameIdAds,
          //   factoryId,
          //   intervalReload,
          //   onAdLoaded,
          //   onAdFailed,
          // );
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
    required String adUnitId,
    required String nameIdAds,
    required String factoryId,
    required double height,
    // required int intervalReload,
    Widget? shimmer,
    Widget? placeholder,
    Function()? onAdLoaded,
    Function(String)? onAdFailed,
  }) {
    print('preload_native --- start show $nameIdAds');

    if (!loadingStateControllers.containsKey(nameIdAds)) {
      print('preload_native --- Error: $nameIdAds không tồn tại, config = $config');
      return placeholder ?? const SizedBox.shrink();
    }
    return FutureBuilder<bool>(
      future: canShowAds(config: config),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          print('preload_native --- await canShowAds $nameIdAds chua xong');
          return placeholder ?? const SizedBox.shrink();
        } else if (snapshot.hasData && snapshot.data == true) {
          return StreamBuilder<bool>(
            stream: getLoadingStream(nameIdAds), // Lắng nghe stream loading
            initialData: !isAdReady(nameIdAds),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true ) {
                print('preload_native --- shimmer $nameIdAds');
                // Đang loading -> Hiển thị loading indicator
                return shimmer ?? ShimmerNativeAds(height: height);
              } else {
                // Không loading nữa -> Xem có quảng cáo chưa
                final ad = adsCache[nameIdAds];
                if (ad != null) {
                  print(
                    'preload_native --- show ads $nameIdAds}',
                  );
                  //start Timer
                  // _schedulePreload(
                  //   adUnitId,
                  //   config,
                  //   nameIdAds,
                  //   factoryId,
                  //   intervalReload,
                  //   onAdLoaded,
                  //   onAdFailed,
                  // );

                  // Có quảng cáo -> Hiển thị AdWidget
                  return SizedBox(
                    height: height,
                    width: double.infinity,
                    child: AdWidget(ad: ad),
                  );
                } else {
                  print('preload_native --- not show $nameIdAds');
                  //start Timer
                  // _schedulePreload(
                  //   adUnitId,
                  //   config,
                  //   nameIdAds,
                  //   factoryId,
                  //   intervalReload,
                  //   onAdLoaded,
                  //   onAdFailed,
                  // );

                  // Không có quảng cáo (lỗi hoặc chưa load) -> Hiển thị placeholder
                  return placeholder ?? const SizedBox.shrink(); // Ẩn hoặc widget mặc định
                }
              }
            },
          );
        } else {
          print(
            'preload_native --- $nameIdAds - canShowAds: config = $config,  ump = ${ConsentManager.instance.canRequestAds}, isShowAllAds = ${Admob.instance.isShowAllAds}, ',
          );
          return const SizedBox.shrink();
        }
      },
    );
  }

  //Hàm schedule preload
  // void _schedulePreload(
  //   String adUnitId,
  //   bool config,
  //   String nameIdAds,
  //   String factoryId,
  //   int intervalReload,
  //   Function()? onAdLoaded,
  //   Function(String)? onAdFailed,
  // ) {
  //   print('preload_native --- schedulePreload $nameIdAds');
  //   // Hủy Timer cũ (nếu có) trước khi tạo Timer mới
  //   _preloadTimers[nameIdAds]?.cancel();
  //   _preloadTimers[nameIdAds] = Timer(Duration(seconds: intervalReload), () {
  //     preloadAd(
  //       adUnitId: adUnitId,
  //       config: config,
  //       nameIdAds: nameIdAds,
  //       factoryId: factoryId,
  //       onAdLoaded: onAdLoaded,
  //       onAdFailed: onAdFailed,
  //       intervalReload: intervalReload, // Truyền preloadInterval
  //     );
  //   });
  // }

  // --- Các hàm tiện ích (dispose) ---
  void disposeAd(String nameIdAds) {
    adsCache[nameIdAds]?.dispose();
    adsCache.remove(nameIdAds);
    loadingStateControllers[nameIdAds]?.close();
    loadingStateControllers.remove(nameIdAds);
    // _preloadTimers[nameIdAds]?.cancel();
    // _preloadTimers.remove(nameIdAds);
  }

  bool isAdReady(String nameIdAds) {
    return adsCache.containsKey(nameIdAds) && adsCache[nameIdAds] != null;
  }

  void disposeAll() {
    adsCache.forEach((key, value) {
      value?.dispose();
    });
    adsCache.clear();

    loadingStateControllers.forEach((key, value) {
      value.close(); // Đóng tất cả StreamController khi disposeAll
    });
    loadingStateControllers.clear();

    // _preloadTimers.forEach((key, value) {
    //   value?.cancel();
    // });
    // _preloadTimers.clear();
  }
}

// import 'dart:async';
//
// import 'package:amazic_ads_flutter/shimmer/shimmer_native_ads.dart';
// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:visibility_detector/visibility_detector.dart';
//
// import '../admob.dart';
// import '../ump/consent_manager.dart';
//
// class NativeAdManager {
//   static final NativeAdManager _instance = NativeAdManager._internal();
//
//   factory NativeAdManager() => _instance;
//
//   NativeAdManager._internal();
//
//   /// Map lưu trữ quảng cáo
//   final Map<String, NativeAd?> _adsCache = {};
//
//   // Map để lưu trữ Timer cho mỗi nameIdAds
//   final Map<String, Timer?> _preloadTimers = {};
//
//   // --- preloadAd (Gần như giữ nguyên) ---
//   Future<void> preloadAd({
//     required String adUnitId,
//     required bool config,
//     required String nameIdAds,
//     required String factoryId,
//     required int intervalReload,
//     Function()? onAdLoaded,
//     Function()? onAdImpression,
//     Function(String)? onAdFailed,
//   }) async {
//     print('preload_native --- start load $nameIdAds');
//
//     if (!await canShowAds(config: config)) {
//       print('preload_native --- canShowAds = false => not preload ads $nameIdAds');
//       return;
//     }
//
//     NativeAd ad = NativeAd(
//       adUnitId: adUnitId,
//       factoryId: factoryId,
//       request: const AdRequest(),
//       listener: NativeAdListener(
//         onAdLoaded: (ad) {
//           print('preload_native --- load xong $nameIdAds');
//           _adsCache[nameIdAds] = ad as NativeAd;
//           onAdLoaded?.call();
//         },
//         onAdFailedToLoad: (ad, error) {
//           print('preload_native --- load false $nameIdAds');
//           ad.dispose();
//           _adsCache[nameIdAds] = null;
//           onAdFailed?.call(error.message);
//         },
//         onAdImpression: (ad) {
//           onAdImpression?.call();
//         },
//       ),
//     );
//     ad.load();
//   }
//
//   NativeAd? getNativeAd(String nameIdAds) {
//     return _adsCache[nameIdAds];
//   }
//
//   Future<bool> canShowAds({required bool config}) async {
//     return config &&
//         ConsentManager.instance.canRequestAds &&
//         Admob.instance.isShowAllAds &&
//         (await Admob.instance.isNetworkActive()) == true;
//   }
//
//   // --- showAd (ĐÃ THAY ĐỔI) ---
//   /// [nameIdAds]: ID dùng khi preload.
//   Widget showAd({
//     Key? key,
//     required bool config,
//     required String adUnitId,
//     required String nameIdAds,
//     required String factoryId,
//     required double height,
//     required int intervalReload,
//     Widget? shimmer,
//     Function()? onAdLoaded,
//     Function(String)? onAdFailed,
//   }) {
//     print('preload_native --- call show $nameIdAds');
//     //Sử dụng StatefulWidget để hiển thị
//     return _NativeAdWidget(
//       key: key,
//       config: config,
//       adUnitId: adUnitId,
//       nameIdAds: nameIdAds,
//       factoryId: factoryId,
//       height: height,
//       intervalReload: intervalReload,
//       shimmer: shimmer,
//       onAdLoaded: onAdLoaded,
//       onAdFailed: onAdFailed,
//     );
//   }
//
//   //Hàm schedule preload (chuyển lên StatefulWidget)
//   // --- Các hàm tiện ích (dispose) ---
//   void disposeAd(String nameIdAds) {
//     _adsCache[nameIdAds]?.dispose();
//     _adsCache.remove(nameIdAds);
//     _preloadTimers[nameIdAds]?.cancel();
//     _preloadTimers.remove(nameIdAds);
//   }
//
//   bool isAdReady(String nameIdAds) {
//     return _adsCache.containsKey(nameIdAds) && _adsCache[nameIdAds] != null;
//   }
//
//   void disposeAll() {
//     _adsCache.forEach((key, value) {
//       value?.dispose();
//     });
//     _adsCache.clear();
//
//     _preloadTimers.forEach((key, value) {
//       value?.cancel();
//     });
//     _preloadTimers.clear();
//   }
// }
//
// //========================================================
// //============== StatefulWidget NativeAdWidget ============
// //========================================================
// class _NativeAdWidget extends StatefulWidget {
//   final bool config;
//   final String adUnitId;
//   final String nameIdAds;
//   final String factoryId;
//   final double height;
//   final int intervalReload;
//   final Widget? shimmer;
//   final Function()? onAdLoaded;
//   final Function(String)? onAdFailed;
//
//   const _NativeAdWidget({
//     Key? key,
//     required this.config,
//     required this.adUnitId,
//     required this.nameIdAds,
//     required this.factoryId,
//     required this.height,
//     required this.intervalReload,
//     this.shimmer,
//     this.onAdLoaded,
//     this.onAdFailed,
//   }) : super(key: key);
//
//   @override
//   __NativeAdWidgetState createState() => __NativeAdWidgetState();
// }
//
// class __NativeAdWidgetState extends State<_NativeAdWidget> with WidgetsBindingObserver {
//   NativeAd? _nativeAd;
//   bool _isLoading = false; //dùng cho trường hợp load ads đầu tiên
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     //Load quảng cáo từ cache (nếu có)
//     _nativeAd = NativeAdManager._instance.getNativeAd(widget.nameIdAds);
//
//     //Nếu chưa có thì mới cần preload
//     if (_nativeAd == null) {
//       print('preload_native --- ${widget.nameIdAds} chưa có dữ liệu => call load ads new');
//       _isLoading = true;
//       _loadAd();
//     } else {
//       print('preload_native --- ${widget.nameIdAds} có dữ liệu => call _schedulePreload');
//
//       //Nếu có sẵn ad thì start timer luôn
//       _isLoading = false;
//       _schedulePreload();
//     }
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     //Không dispose ad ở đây mà để NativeAdManager quản lý
//     _cancelPreloadTimer();
//     _nativeAd?.dispose();
//     super.dispose();
//   }
//
//   //Hàm load quảng cáo
//   Future<void> _loadAd() async {
//     NativeAdManager().preloadAd(
//       adUnitId: widget.adUnitId,
//       config: widget.config,
//       nameIdAds: widget.nameIdAds,
//       factoryId: widget.factoryId,
//       intervalReload: widget.intervalReload,
//       onAdLoaded: () {
//         print('preload_native --- onAdLoaded');
//         //Khi load thành công thì lấy quảng cáo và setState
//         final oldAd = _nativeAd;
//         final newAd = NativeAdManager._instance.getNativeAd(widget.nameIdAds);
//
//         setState(() {
//           _nativeAd = newAd;
//           _isLoading = false;
//         });
//         Future.microtask(() {
//           oldAd?.dispose();
//         },);
//       },
//       onAdFailed: (error) {
//         print('preload_native --- onAdFailed: load ads failed $error');
//         setState(() {
//           _isLoading = false;
//         });
//         _schedulePreload();
//       },
//       onAdImpression: () {
//         print('preload_native --- onAdImpression: show ads ${widget.nameIdAds}');
//         _schedulePreload();
//       },
//     );
//   }
//
//   //Hàm schedule preload
//   void _schedulePreload() {
//     if (widget.intervalReload == 0) {
//       return;
//     }
//     print('preload_native --- start _schedulePreload ${widget.nameIdAds}');
//     _cancelPreloadTimer();
//     NativeAdManager._instance._preloadTimers[widget.nameIdAds] = Timer(
//       Duration(seconds: widget.intervalReload),
//       () {
//         print('preload_native --- interval gọi load lại ${widget.nameIdAds}');
//         _loadAd(); // Load lại
//       },
//     );
//   }
//
//   void _cancelPreloadTimer() {
//     NativeAdManager._instance._preloadTimers[widget.nameIdAds]?.cancel();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     if (state == AppLifecycleState.paused) {
//       _cancelPreloadTimer();
//     } else if (state == AppLifecycleState.resumed) {
//       _schedulePreload();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return widget.shimmer ?? ShimmerNativeAds(height: widget.height);
//     }
//
//     if (_nativeAd != null) {
//       return VisibilityDetector(
//         key: Key('${widget.nameIdAds}_${widget.hashCode}'),
//         onVisibilityChanged: (info) {
//           if (info.visibleFraction == 0) {
//             _cancelPreloadTimer();
//           } else {
//             _schedulePreload();
//           }
//         },
//         child: SizedBox(
//           width: MediaQuery.of(context).size.width,
//           height: widget.height,
//           child: AdWidget(
//             key: ValueKey('${widget.nameIdAds}_${_nativeAd.hashCode}'),
//             ad: _nativeAd!,
//           ),
//         ),
//       );
//     }
//
//     return const SizedBox.shrink();
//   }
// }
