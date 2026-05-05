import 'dart:async';

import 'package:amazic_ads_flutter/amazic_ads_flutter.dart';
import 'package:amazic_ads_flutter/shimmer/shimmer_banner_ads.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:amazic_ads_flutter/utils/adjust_util.dart';
import 'package:amazic_ads_flutter/utils/event_log.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class CollapseBannerAds extends StatefulWidget {
  final String idAds;
  final CollapseBannerType type;
  final bool config;
  final Function()? onAdLoaded;
  final Function()? onAdFailedToLoad;
  final Function()? onAdImpression;
  final Function()? onAdClicked;
  final Function()? onAdDisable;
  final int refreshSec;

  /// dùng trong việc log event của tên quảng cáo vd: banner_all
  final String name;

  const CollapseBannerAds({
    super.key,
    required this.idAds,
    required this.type,
    required this.config,
    required this.refreshSec,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdImpression,
    this.onAdClicked,
    this.onAdDisable,
    required this.name,
  });

  @override
  State<CollapseBannerAds> createState() => CollapseBannerAdsState();
}

class CollapseBannerAdsState extends State<CollapseBannerAds> with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isLoading = false;
  bool _shouldHide = false;

  Timer? _timerRefresh;
  bool isCanRefreshAd = true;

  ///biến kiểm tra có đang ở màn show Collapse Banner ,
  /// để khi click Continue (ở WelcomeBack có cho reload hay k)
  bool isScreenShowCollapse = true;

  void setIsOnScreenShowCollapse({required bool isOnScreenShowCollapse}) {
    isScreenShowCollapse = isOnScreenShowCollapse;
  }

  void setIsCanRefreshAd({required bool isCan}) {
    isCanRefreshAd = isCan;
    if (isCan && isScreenShowCollapse) {
      loadCollapseAds();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadCollapseAds();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    stopRefreshTime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      print('admob_ads --- collapse_banner: AppLifecycleState.paused');
      stopRefreshTime();
    } else if (state == AppLifecycleState.resumed) {
      print('admob_ads --- collapse_banner: AppLifecycleState.resumed');
      startRefreshTime();
    }
  }

  Future<void> closeCollapse() async {
    _bannerAd?.dispose();
  }

  Future<void> reloadCollapse() async {
    stopRefreshTime();
    loadCollapseAds();
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldHide) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return ShimmerBannerAds();
    }

    if (_bannerAd != null) {
      return Container(
        key: Key('${widget.name}_${_bannerAd.hashCode}'),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black, width: 1)),
        ),
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(key: ValueKey('${widget.name}_${_bannerAd.hashCode}'), ad: _bannerAd!),
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

  loadCollapseAds() async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.sizeOf(context).width.truncate(),
    );
    print('admob_ads --- collapse_banner: size = $size');
    if (size == null) {
      setState(() {
        _shouldHide = true;
      });
      widget.onAdDisable?.call();
      return;
    }

    if (!await canShowAds()) {
      print('admob_ads --- collapse_banner: hide collapse');
      setState(() {
        _shouldHide = true;
      });
      widget.onAdDisable?.call();
      return;
    }

    setState(() {
      _isLoading = true;
      _shouldHide = false;
    });

    _bannerAd?.dispose();

    AdRequest adRequest = AdRequest();
    if (widget.type == CollapseBannerType.collapsible_bottom) {
      adRequest = AdRequest(extras: {"collapsible": "bottom"});
    } else if (widget.type == CollapseBannerType.collapsible_top) {
      adRequest = AdRequest(extras: {"collapsible": "top"});
    }
    print('admob_ads --- collapse_banner: start request');
    BannerAd(
      size: size,
      adUnitId: widget.idAds,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (isScreenShowCollapse) {
            print('admob_ads --- collapse_banner: onAdLoaded');
            setState(() {
              _bannerAd = ad as BannerAd;
              _isLoading = false;
            });
          } else {
            print(
              'admob_ads --- collapse_banner: NOT onAdLoaded isScreenShowCollapse = $isScreenShowCollapse',
            );
          }
          widget.onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          print('admob_ads --- collapse_banner: onAdFailedToLoad');
          ad.dispose();
          setState(() {
            _bannerAd = null;
            _isLoading = false;
            _shouldHide = true;
          });
          startRefreshTime();
          widget.onAdFailedToLoad?.call();
        },
        onAdImpression: (ad) {
          print('admob_ads --- collapse_banner: onAdImpression');
          startRefreshTime();
          widget.onAdImpression?.call();
          EventLog.logEvent('${widget.name}_view');
        },
        onAdClicked: (ad) {
          print('admob_ads --- collapse_banner: onAdClicked');
          widget.onAdClicked?.call();
          EventLog.logEvent('${widget.name}_click');
        },
        onAdClosed: (ad) {
          print('admob_ads --- collapse_banner: onAdClosed');
        },
        onAdOpened: (ad) {
          print('admob_ads --- collapse_banner: onAdOpened');
        },
        onAdWillDismissScreen: (ad) {
          print('admob_ads --- collapse_banner: onAdWillDismissScreen');
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          print('admob_ads --- collapse_banner: onPaidEvent');
          AdjustUtil.instance.trackRevenue(
            network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
            revenue: valueMicros,
            currency: currencyCode,
            adUnitId: widget.idAds,
            adFormat: widget.name
          );
        },
      ),
      request: adRequest,
    ).load();
  }

  ///reload native width interval time
  void startRefreshTime() {
    if (widget.refreshSec == 0) {
      return;
    }

    stopRefreshTime();
    print('admob_ads --- collapse_banner: startRefreshTime');
    _timerRefresh = Timer.periodic(Duration(seconds: widget.refreshSec), (timer) {
      if (isCanRefreshAd && isScreenShowCollapse) {
        print('admob_ads --- collapse_banner: RefreshSec - ${widget.refreshSec} Done');
        loadCollapseAds();
      } else {
        print(
          'admob_ads --- collapse_banner: Can not refresh ad isCanRefreshAd = $isCanRefreshAd , isScreenShowCollapse = $isScreenShowCollapse',
        );
      }
    });
  }

  void stopRefreshTime() {
    _timerRefresh?.cancel();
    _timerRefresh = null;
  }
}
