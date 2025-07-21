import 'dart:async';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/shimmer/shimmer_native_ads.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
      print('admob_ads --- native_ads: AppLifecycleState.paused');
      stopRefreshTime();
    }else if(state == AppLifecycleState.resumed){
      print('admob_ads --- native_ads: AppLifecycleState.resumed');
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
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: widget.height,
        child: AdWidget(key: ValueKey(_nativeAd), ad: _nativeAd!),
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
      print('admob_ads --- native_ads: hide native');
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
    print('admob_ads --- native_ads: start request');
    _nativeAd = NativeAd(
      adUnitId: widget.idAds,
      factoryId: widget.factoryId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('admob_ads --- native_ads: onAdLoaded');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          widget.onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          print('admob_ads --- native_ads: onAdFailedToLoad');
          if (mounted) {
            setState(() {
              _nativeAd = null;
              _isLoading = false;
              _shouldHide = true;
            });
          }
          startRefreshTime();
          widget.onAdFailedToLoad?.call();
        },
        onAdOpened: (ad) {
          print('admob_ads --- native_ads: onAdOpened');
        },
        onAdWillDismissScreen: (ad) {
          print('admob_ads --- native_ads: onAdWillDismissScreen');
        },
        onAdClosed: (ad) {
          print('admob_ads --- native_ads: onAdClosed');
        },
        onAdImpression: (ad) {
          print('admob_ads --- native_ads: onAdImpression');
          startRefreshTime();
          widget.onAdImpression?.call();
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          print('admob_ads --- native_ads: onPaidEvent');
          AdjustUtil.instance.trackRevenue(
            network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
            revenue: valueMicros,
            currency: currencyCode,
          );
        },
        onAdClicked: (ad) {
          print('admob_ads --- native_ads: onAdClicked');
          widget.onAdClicked?.call();
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
    print('admob_ads --- native_ads: startRefreshTime');
    _timerRefresh = Timer.periodic(Duration(seconds: widget.refreshSec), (timer) {
      print('admob_ads --- native_ads: RefreshSec - ${widget.refreshSec} Done');
      loadAdsQuietly();
    });
  }

  void stopRefreshTime() {
    _timerRefresh?.cancel();
    _timerRefresh = null;
  }

  ///load ads before show
  loadAdsQuietly() async {
    if (!await canShowAds()) {
      print('admob_ads --- native_ads: Quietly - hide native');
      return;
    }
    late NativeAd tempAd;

    tempAd = NativeAd(
      adUnitId: widget.idAds,
      factoryId: widget.factoryId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _nativeAd?.dispose();
          _nativeAd = null;
          if (mounted) {
            setState(() {
              _nativeAd = ad as NativeAd?;
              _isLoading = false;
              _shouldHide = false;
            });
          }
          print('admob_ads --- native_ads: Quietly - onAdLoaded $_nativeAd');
        },
        onAdFailedToLoad: (ad, error) {
          print('admob_ads --- native_ads: Quietly - onAdFailedToLoad');
          ad.dispose();
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          print('admob_ads --- native_ads: Quietly - onPaidEvent');
          AdjustUtil.instance.trackRevenue(
            network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
            revenue: valueMicros,
            currency: currencyCode,
          );
        },
        onAdImpression: (ad) {
          print('admob_ads --- native_ads: Quietly - onAdImpression');
        },
      ),
      request: const AdRequest(),
    );
    tempAd.load();
  }
}
