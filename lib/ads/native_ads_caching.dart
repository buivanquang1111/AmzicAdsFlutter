import 'dart:async';
import 'dart:collection'; // Cần cho Queue

import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/shimmer/shimmer_native_ads.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:amazic_ads_flutter/utils/event_log.dart';
import 'package:amazic_ads_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../utils/adjust_util.dart';

class NativeAdsCaching extends StatefulWidget {
  final String idAds;
  final bool config;
  final double height;
  final String factoryId;
  final Widget? shimmer;
  final Function()? onAdLoaded;
  final Function()? onAdFailedToLoad;
  final Function()? onAdImpression;
  final Function()? onAdClicked;
  final int refreshSec;

  final String name;

  const NativeAdsCaching({
    super.key,
    required this.idAds,
    required this.config,
    required this.height,
    required this.factoryId,
    required this.refreshSec,
    this.shimmer,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdImpression,
    this.onAdClicked,
    required this.name,
  });

  @override
  State<NativeAdsCaching> createState() => _NativeAdsCachingState();
}

class _NativeAdsCachingState extends State<NativeAdsCaching> with WidgetsBindingObserver {
  NativeAd? _nativeAd; // Quảng cáo đang hiển thị
  bool _isLoading = false;
  bool _shouldHide = false;
  Timer? _timerRefresh;

  // --- START: Các biến quản lý Ad Cache ---
  final Queue<NativeAd> _adCache = Queue<NativeAd>(); // Hàng đợi lưu trữ quảng cáo đã tải
  static const int _maxCacheSize = 1; // Giữ tối đa 2 quảng cáo trong cache
  bool _isFillingCache = false; // Cờ để tránh việc lấp đầy cache nhiều lần cùng lúc
  // --- END: Các biến quản lý Ad Cache ---

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadAds(); // Tải quảng cáo chính lần đầu
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nativeAd?.dispose();
    // Dọn dẹp tất cả quảng cáo trong cache
    for (var ad in _adCache) {
      ad.dispose();
    }
    _adCache.clear();
    stopRefreshTime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      print('admob_ads --- native_ads: ${widget.name} AppLifecycleState.paused');
      stopRefreshTime();
    } else if (state == AppLifecycleState.resumed) {
      print('admob_ads --- native_ads: ${widget.name} AppLifecycleState.resumed');
      // Nếu có quảng cáo đang hiển thị, khởi động lại chu kỳ refresh
      if (_nativeAd != null) {
        startRefreshTime();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldHide) return const SizedBox.shrink();
    if (_isLoading) return widget.shimmer ?? ShimmerNativeAds(height: widget.height);
    if (_nativeAd != null) {
      return VisibilityDetector(
        key: Key('${widget.name}'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction == 0) {
            print('admob_ads --- native_ads: ${widget.name} HIDDEN');
            stopRefreshTime();
          } else {
            print('admob_ads --- native_ads: ${widget.name} SHOW');
            startRefreshTime();
          }
        },
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: widget.height,
          child: AdWidget(key: ValueKey('${widget.name}_${_nativeAd.hashCode}'), ad: _nativeAd!),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<bool> canShowAds() async {
    return widget.config &&
        ConsentManager.instance.canRequestAds &&
        Admob.instance.isShowAllAds &&
        (await Admob.instance.isNetworkActive()) == true;
  }

  /// Tải quảng cáo chính lần đầu, có shimmer
  void loadAds() async {
    if (_isLoading) return;
    if (!await canShowAds()) {
      if (mounted) setState(() => _shouldHide = true);
      return;
    }
    if (mounted) setState(() => _isLoading = true);

    await _nativeAd?.dispose();
    _nativeAd = null;

    print('admob_ads --- native_ads: ${widget.name} start request');
    EventLog.logEvent('${widget.name}_request');
    NativeAd(
      adUnitId: widget.idAds,
      factoryId: widget.factoryId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('admob_ads --- native_ads: ${widget.name} onAdLoaded');
          EventLog.logEvent('${widget.name}_load');
          logNativeMediation(ad: ad, nameAds: widget.name);
          if (mounted) {
            setState(() {
              _isLoading = false;
              _nativeAd = ad as NativeAd;
            });
            widget.onAdLoaded?.call();
            _fillAdCache(); // <--- Bắt đầu lấp đầy cache sau khi có quảng cáo đầu tiên
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('admob_ads --- native_ads: ${widget.name} onAdFailedToLoad');
          EventLog.logEvent('${widget.name}_load_failed');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _shouldHide = true;
            });
          }
          startRefreshTime(); // <--- Bắt đầu chu kỳ refresh
          widget.onAdFailedToLoad?.call();
          // Có thể thêm cơ chế retry backoff ở đây nếu muốn
        },
        onAdImpression: (ad) {
          print('admob_ads --- native_ads: ${widget.name} onAdImpression');
          startRefreshTime(); // <--- Bắt đầu chu kỳ refresh
          widget.onAdImpression?.call();
          EventLog.logEvent('${widget.name}_view');
        },
        // ... các listener khác
        onAdClicked: (ad) {
          print('admob_ads --- native_ads: ${widget.name} onAdClicked');
          widget.onAdClicked?.call();
          EventLog.logEvent('${widget.name}_click');
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          print('admob_ads --- native_ads: ${widget.name} onPaidEvent');
          AdjustUtil.instance.trackRevenue(
            network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
            revenue: valueMicros,
            currency: currencyCode,
          );
        },
      ),
      request: const AdRequest(),
    ).load();
  }

  /// <--- HÀM MỚI: Liên tục lấp đầy cache quảng cáo ---
  void _fillAdCache() async {
    if (_isFillingCache || _adCache.length >= _maxCacheSize) {
      return; // Không làm gì nếu đang lấp đầy hoặc cache đã đầy
    }
    _isFillingCache = true;
    print('admob_ads --- native_ads: ${widget.name} Cache - Start filling. Current size: ${_adCache.length}');

    // Tải đủ số lượng quảng cáo còn thiếu
    int missingAds = _maxCacheSize - _adCache.length;
    for (int i = 0; i < missingAds; i++) {
      if (!await canShowAds()) break; // Dừng nếu không thể hiển thị quảng cáo

      NativeAd(
        adUnitId: widget.idAds,
        factoryId: widget.factoryId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            print('admob_ads --- native_ads: ${widget.name} Cache - Ad loaded and added to cache.');
            _adCache.add(ad as NativeAd);
          },
          onAdFailedToLoad: (ad, error) {
            print('admob_ads --- native_ads: ${widget.name} Cache - Failed to load ad for cache. Error: $error');
            ad.dispose();
          },
          onAdImpression: (ad) {
            startRefreshTime();
            print('admob_ads --- native_ads: ${widget.name} Cache - impression');
          },
        ),
        request: const AdRequest(),
      ).load();
    }
    _isFillingCache = false;
  }

  /// <--- HÀM MỚI: Hiển thị quảng cáo tiếp theo từ cache ---
  void _showNextAdFromCache() async {
    print('admob_ads --- native_ads: ${widget.name} Refresh - Trying to show next ad from cache.');
    if (_adCache.isNotEmpty) {
      // Nếu cache có quảng cáo, lấy ra hiển thị ngay lập tức
      final oldAd = _nativeAd;
      final newAd = _adCache.removeFirst(); // Lấy quảng cáo đầu tiên

      if (mounted) {
        setState(() {
          _nativeAd = newAd;
        });
        await Future.delayed(const Duration(milliseconds: 500)); // Đợi một chút để UI cập nhật
        oldAd?.dispose();
        print('admob_ads --- native_ads: ${widget.name} Refresh - Displayed ad from cache.');
        _fillAdCache(); // <--- Lấp đầy lại cache sau khi đã dùng một quảng cáo
      }
    } else {
      // Nếu cache rỗng, quay về cách cũ: tải một quảng cáo mới để hiển thị ngay
      print('admob_ads --- native_ads: ${widget.name} Refresh - Cache is empty. Loading ad quietly.');
      loadAdsQuietly();
    }
  }

  /// Tải quảng cáo nền (chỉ dùng khi cache rỗng)
  void loadAdsQuietly() async {
    if (!await canShowAds()) return;

    NativeAd(
      adUnitId: widget.idAds,
      factoryId: widget.factoryId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          final oldAd = _nativeAd;
          final newAd = ad as NativeAd;
          if (mounted) {
            setState(() => _nativeAd = newAd);
            Future.microtask(() => oldAd?.dispose());
          } else {
            newAd.dispose();
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('admob_ads --- native_ads: ${widget.name} Quietly - onAdFailedToLoad');
          ad.dispose();
          startRefreshTime(); // Vẫn giữ để bắt đầu chu kỳ mới
        },
        onAdImpression: (ad) {
          startRefreshTime(); // Vẫn giữ để bắt đầu chu kỳ mới
        },
        // ... các listener khác
      ),
      request: const AdRequest(),
    ).load();
  }


  /// Bắt đầu timer cho chu kỳ refresh
  void startRefreshTime() {
    if (widget.refreshSec <= 0) return;
    stopRefreshTime();
    print('admob_ads --- native_ads: ${widget.name} startRefreshTime');
    _timerRefresh = Timer(Duration(seconds: widget.refreshSec), () {
      print('admob_ads --- native_ads: ${widget.name} RefreshSec - ${widget.refreshSec} Done');
      _showNextAdFromCache(); // <--- THAY ĐỔI: Gọi hàm hiển thị từ cache
    });
  }

  void stopRefreshTime() {
    _timerRefresh?.cancel();
    _timerRefresh = null;
  }
}