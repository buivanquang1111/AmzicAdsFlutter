import 'dart:async';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/shimmer/shimmer_native_ads.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:amazic_ads_flutter/utils/event_log.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../utils/adjust_util.dart';

class NativeAds extends StatefulWidget {
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
  /// dùng trong việc log event của tên quảng cáo vd: banner_all
  final String name;

  const NativeAds({
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
  State<NativeAds> createState() => _NativeAdsState();
}

class _NativeAdsState extends State<NativeAds> with WidgetsBindingObserver{
  NativeAd? _nativeAd;
  bool _isLoading = false;
  bool _shouldHide = false;

  Timer? _timerRefresh;

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
    if(state == AppLifecycleState.paused){
      print('admob_ads --- native_ads: ${widget.name} AppLifecycleState.paused');
      stopRefreshTime();
    }else if(state == AppLifecycleState.resumed){
      print('admob_ads --- native_ads: ${widget.name} AppLifecycleState.resumed');
      startRefreshTime();
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
        key: const Key('native_ads'),
        onVisibilityChanged: (info) {
          if(info.visibleFraction == 0){
            print('admob_ads --- native_ads: ${widget.name} HIDDEN');
            stopRefreshTime();
          }else{
            print('admob_ads --- native_ads: ${widget.name} SHOW');
            startRefreshTime();
          }
        },
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: widget.height,
          child: AdWidget(key: ValueKey(_nativeAd), ad: _nativeAd!),
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

  loadAds() async {
    if (!await canShowAds()) {
      print('admob_ads --- native_ads: ${widget.name} hide native');
      EventLog.logEvent('${widget.name}_hide');
      if (mounted) {
        setState(() {
          _shouldHide = true;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _shouldHide = false;
      });
    }
    _nativeAd?.dispose();
    print('admob_ads --- native_ads: ${widget.name} start request');
    EventLog.logEvent('${widget.name}_request');
    _nativeAd = NativeAd(
      adUnitId: widget.idAds,
      factoryId: widget.factoryId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('admob_ads --- native_ads: ${widget.name} onAdLoaded');
          EventLog.logEvent('${widget.name}_load');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          widget.onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          print('admob_ads --- native_ads: ${widget.name} onAdFailedToLoad');
          EventLog.logEvent('${widget.name}_load_failed');
          if (mounted) {
            setState(() {
              _nativeAd = null;
              _isLoading = false;
              _shouldHide = true;
            });
          }
          print('admob_ads --- native_ads: ${widget.name} onAdFailedToLoad - startRefreshTime');
          startRefreshTime();
          widget.onAdFailedToLoad?.call();
        },
        onAdOpened: (ad) {
          print('admob_ads --- native_ads: ${widget.name} onAdOpened');
        },
        onAdWillDismissScreen: (ad) {
          print('admob_ads --- native_ads: ${widget.name} onAdWillDismissScreen');
        },
        onAdClosed: (ad) {
          print('admob_ads --- native_ads: ${widget.name} onAdClosed');
        },
        onAdImpression: (ad) {
          print('admob_ads --- native_ads: ${widget.name} onAdImpression');
          startRefreshTime();
          widget.onAdImpression?.call();
          EventLog.logEvent('${widget.name}_view');
        },
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
      ),
      request: const AdRequest(),
    )..load();
  }

  ///reload native with interval time
  void startRefreshTime() {
    if (widget.refreshSec == 0) {
      return;
    }
    stopRefreshTime();
    print('admob_ads --- native_ads: ${widget.name} startRefreshTime');
    _timerRefresh = Timer.periodic(Duration(seconds: widget.refreshSec), (timer) {
      print('admob_ads --- native_ads: ${widget.name} RefreshSec - ${widget.refreshSec} Done');
      loadAdsQuietly();
    });
  }

  void stopRefreshTime() {
    print('admob_ads --- native_ads: ${widget.name} stopRefreshTime');
    _timerRefresh?.cancel();
    _timerRefresh = null;
  }

  ///load ads before show
  loadAdsQuietly() async {
    if (!await canShowAds()) {
      print('admob_ads --- native_ads: ${widget.name} Quietly - hide native');
      return;
    }
    late NativeAd tempAd;

    EventLog.logEvent('${widget.name}_quietly_request');
    tempAd = NativeAd(
      adUnitId: widget.idAds,
      factoryId: widget.factoryId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _nativeAd?.dispose();
          _nativeAd = null;
          EventLog.logEvent('${widget.name}_quietly_load');
          if (mounted) {
            setState(() {
              _nativeAd = ad as NativeAd?;
              _isLoading = false;
              _shouldHide = false;
            });
          }
          print('admob_ads --- native_ads: ${widget.name} Quietly - onAdLoaded $_nativeAd');
        },
        onAdFailedToLoad: (ad, error) {
          print('admob_ads --- native_ads: ${widget.name} Quietly - onAdFailedToLoad');
          ad.dispose();
          EventLog.logEvent('${widget.name}_quietly_load_failed');
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          print('admob_ads --- native_ads: ${widget.name} Quietly - onPaidEvent');
          AdjustUtil.instance.trackRevenue(
            network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
            revenue: valueMicros,
            currency: currencyCode,
          );
        },
        onAdImpression: (ad) {
          print('admob_ads --- native_ads: ${widget.name} Quietly - onAdImpression');
          EventLog.logEvent('${widget.name}_quietly_view');
        },
        onAdClicked: (ad) {
          print('admob_ads --- native_ads: ${widget.name} Quietly - onAdClicked');
          EventLog.logEvent('${widget.name}_quietly_click');
        },
      ),
      request: const AdRequest(),
    );
    tempAd.load();
  }
}
