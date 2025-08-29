import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../admob.dart';
import '../shimmer/shimmer_native_ads.dart';
import '../ump/consent_manager.dart';
import '../utils/adjust_util.dart';
import '../utils/event_log.dart';

class NativeAdsReload extends StatefulWidget {
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

  const NativeAdsReload({
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
  State<NativeAdsReload> createState() => _NativeAdsReloadState();
}

class _NativeAdsReloadState extends State<NativeAdsReload> with WidgetsBindingObserver {
  NativeAd? _nativeAd;
  bool _isLoading = false;
  bool _shouldHide = false;

  Timer? _timerRefresh;

  // --- START: Các biến cho cơ chế Backoff ---
  int _failedAttemptCount = 0;
  static const int _initialFailedRetryDelaySec = 10;
  static const int _maxFailedRetryDelaySec = 300;
  // --- END: Các biến cho cơ chế Backoff ---

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadAds();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nativeAd?.dispose();
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
      // Nếu không có quảng cáo và không bị ẩn, thử tải lại với shimmer
      if (_nativeAd == null && !_isLoading && !_shouldHide) {
        loadAds();
      } else if (_nativeAd != null) {
        // Nếu đã có quảng cáo, bắt đầu lại chu kỳ refresh
        startRefreshTime();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldHide) {
      return const SizedBox.shrink();
    }
    if (_isLoading) {
      return widget.shimmer ?? ShimmerNativeAds(height: widget.height);
    }
    if (_nativeAd != null) {
      return VisibilityDetector(
        key: Key('${widget.name}_${_nativeAd.hashCode}'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction == 0) {
            print('admob_ads --- native_ads: ${widget.name} HIDDEN');
            stopRefreshTime();
          } else {
            print('admob_ads --- native_ads: ${widget.name} SHOW');
            // Logic refresh đã được chuyển vào onAdImpression, không cần ở đây
          }
        },
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: widget.height,
          child: AdWidget(
            key: ValueKey('${widget.name}_${_nativeAd.hashCode}'),
            ad: _nativeAd!,
          ),
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

  /// Hàm tải quảng cáo lần đầu, có hiển thị shimmer
  void loadAds() async {
    if (_isLoading) return;
    if (!await canShowAds()) {
      print('admob_ads --- native_ads: ${widget.name} hide native');
      EventLog.logEvent('${widget.name}_hide');
      if (mounted) setState(() => _shouldHide = true);
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _shouldHide = false;
      });
    }

    stopRefreshTime();
    await _nativeAd?.dispose();
    _nativeAd = null;

    print('admob_ads --- native_ads: ${widget.name} start request');
    EventLog.logEvent('${widget.name}_request');
    NativeAd(
      adUnitId: widget.idAds,
      factoryId: widget.factoryId,
      listener: _createAdListener(isQuietLoad: false),
      request: const AdRequest(),
    ).load();
  }

  /// Hàm tải quảng cáo nền, không hiển thị shimmer
  void loadAdsQuietly() async {
    if (!await canShowAds()) {
      print('admob_ads --- native_ads: ${widget.name} Quietly - hide native');
      return;
    }

    EventLog.logEvent('${widget.name}_quietly_request');
    NativeAd(
      adUnitId: widget.idAds,
      factoryId: widget.factoryId,
      listener: _createAdListener(isQuietLoad: true),
      request: const AdRequest(),
    ).load();
  }

  /// Tạo listener chung cho cả hai hàm load ads
  NativeAdListener _createAdListener({required bool isQuietLoad}) {
    return NativeAdListener(
      onAdLoaded: (ad) {
        final logPrefix = isQuietLoad ? "Quietly -" : "";
        print('admob_ads --- native_ads: ${widget.name} $logPrefix onAdLoaded');
        EventLog.logEvent(isQuietLoad ? '${widget.name}_quietly_load' : '${widget.name}_load');

        // <--- QUAN TRỌNG: Reset bộ đếm khi bất kỳ lần tải nào thành công
        _failedAttemptCount = 0;

        final newAd = ad as NativeAd;
        if (mounted) {
          final oldAd = _nativeAd;
          setState(() {
            _nativeAd = newAd;
            if (!isQuietLoad) _isLoading = false; // Chỉ tắt shimmer nếu là load chính
            _shouldHide = false;
          });
          Future.microtask(() => oldAd?.dispose());
        } else {
          newAd.dispose();
        }
        if (!isQuietLoad) widget.onAdLoaded?.call();
      },
      onAdFailedToLoad: (ad, error) {
        final logPrefix = isQuietLoad ? "Quietly -" : "";
        print('admob_ads --- native_ads: ${widget.name} $logPrefix onAdFailedToLoad');
        EventLog.logEvent(isQuietLoad ? '${widget.name}_quietly_load_failed' : '${widget.name}_load_failed');
        ad.dispose();

        // <--- QUAN TRỌNG: Bất kỳ lần load nào thất bại đều sẽ kích hoạt cơ chế backoff
        _failedAttemptCount++;
        _startRetryTimer(isRetryingMainAd: !isQuietLoad); // Quyết định retry hàm nào

        if (!isQuietLoad) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _shouldHide = true;
            });
          }
          widget.onAdFailedToLoad?.call();
        }
      },
      onAdImpression: (ad) {
        print('admob_ads --- native_ads: ${widget.name} onAdImpression');
        startRefreshTime(); // Bắt đầu chu kỳ refresh bình thường khi quảng cáo hiển thị
        widget.onAdImpression?.call();
        EventLog.logEvent('${widget.name}_view');
      },
      // ... các listener khác
      onPaidEvent: (ad, valueMicros, precision, currencyCode) {
        print('admob_ads --- native_ads: ${widget.name} onPaidEvent');
        AdjustUtil.instance.trackRevenue(
          network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
          revenue: valueMicros,
          currency: currencyCode,
        );
      },
      onAdClicked: (ad) {
        print('admob_ads --- native_ads: ${widget.name} onAdClicked');
        widget.onAdClicked?.call();
        EventLog.logEvent('${widget.name}_click');
      },
    );
  }

  /// Bắt đầu timer cho chu kỳ refresh bình thường
  void startRefreshTime() {
    if (widget.refreshSec <= 0) return;
    stopRefreshTime();
    print('admob_ads --- native_ads: ${widget.name} startRefreshTime');
    _timerRefresh = Timer(Duration(seconds: widget.refreshSec), () {
      print('admob_ads --- native_ads: ${widget.name} RefreshSec - ${widget.refreshSec} Done');
      loadAdsQuietly();
    });
  }

  void stopRefreshTime() {
    _timerRefresh?.cancel();
    _timerRefresh = null;
  }

  /// <--- HÀM MỚI: Bắt đầu timer thử lại sau khi thất bại ---
  void _startRetryTimer({required bool isRetryingMainAd}) {
    stopRefreshTime();

    // Tính toán độ trễ với backoff lũy thừa
    final backoffMultiplier = pow(2, min(_failedAttemptCount - 1, 8));
    int delay = (_initialFailedRetryDelaySec * backoffMultiplier).toInt();
    if (delay > _maxFailedRetryDelaySec) delay = _maxFailedRetryDelaySec;

    print('admob_ads --- native_ads: ${widget.name} Starting failed load retry timer in $delay seconds.');
    _timerRefresh = Timer(Duration(seconds: delay), () {
      // Quyết định gọi hàm nào để thử lại
      if (isRetryingMainAd) {
        print('admob_ads --- native_ads: ${widget.name} Retrying with loadAds()');
        loadAds(); // Thử lại với shimmer vì không có quảng cáo nào đang hiển thị
      } else {
        print('admob_ads --- native_ads: ${widget.name} Retrying with loadAdsQuietly()');
        loadAdsQuietly(); // Thử lại không shimmer vì đã có quảng cáo cũ
      }
    });
  }
}