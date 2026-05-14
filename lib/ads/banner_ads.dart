import 'dart:async';

import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/shimmer/shimmer_banner_ads.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:amazic_ads_flutter/utils/event_log.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/adjust_util.dart';

class BannerAds extends StatefulWidget {
  final String idAds;
  final Function()? onAdLoaded;
  final Function()? onAdFailedToLoad;
  final Function()? onAdImpression;
  final Function()? onAdClicked;
  final Function()? onAdDisable;
  final bool config;

  /// dùng trong việc log event của tên quảng cáo vd: banner_all
  final String name;
  final int refreshSec;

  const BannerAds({
    super.key,
    required this.idAds,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdImpression,
    this.onAdClicked,
    this.onAdDisable,
    required this.config,
    required this.name,
    required this.refreshSec,
  });

  @override
  State<BannerAds> createState() => _BannerAdsState();
}

class _BannerAdsState extends State<BannerAds> with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isLoading = false;
  bool _shouldHide = false;

  Timer? _timerRefresh;
  bool isCanRefreshAd = true;

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
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      print('admob_ads --- banner_ads: AppLifecycleState.paused');
      stopRefreshTime();
    } else if (state == AppLifecycleState.resumed) {
      print('admob_ads --- banner_ads: AppLifecycleState.resumed');
      startRefreshTime();
    }
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
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black, width: 1)),
        ),
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  loadAds() async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.sizeOf(context).width.truncate(),
    );
    print('admob_ads --- banner_ads: size= $size');
    if (size == null) {
      setState(() {
        _shouldHide = true;
      });
      EventLog.logEvent('${widget.name}_fail_size_null');
      widget.onAdDisable?.call();
      return;
    }
    bool? isNetwork = await Admob.instance.isNetworkActive();
    if (widget.config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        isNetwork == false) {
      print('admob_ads --- banner_ads: hide banner');
      EventLog.logEvent(
        '${widget.name}_not_request',
        parameters: {
          'config': widget.config,
          'ump': ConsentManager.instance.canRequestAds,
          'isShowAllAds': Admob.instance.isShowAllAds,
          'isNetwork': isNetwork == true,
        },
      );
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
    print('admob_ads --- banner_ads: start request');
    EventLog.logEvent('${widget.name}_request');
    BannerAd(
      size: size,
      adUnitId: widget.idAds,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('admob_ads --- banner_ads: onAdLoaded');
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoading = false;
          });
          widget.onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          print('admob_ads --- banner_ads: onAdFailedToLoad');
          EventLog.logEvent('${widget.name}_fail', parameters: {'error': error.message});
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
          print('admob_ads --- banner_ads: onAdImpression');
          startRefreshTime();
          widget.onAdImpression?.call();
          EventLog.logEvent('${widget.name}_view');
        },
        onAdClicked: (ad) {
          print('admob_ads --- banner_ads: onAdClicked');
          widget.onAdClicked?.call();
          EventLog.logEvent('${widget.name}_click');
        },
        onAdClosed: (ad) {
          print('admob_ads --- banner_ads: onAdClosed');
        },
        onAdOpened: (ad) {
          print('admob_ads --- banner_ads: onAdOpened');
        },
        onAdWillDismissScreen: (ad) {
          print('admob_ads --- banner_ads: onAdWillDismissScreen');
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          print('admob_ads --- banner_ads: onPaidEvent');
          AdjustUtil.instance.trackRevenue(
            network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
            revenue: valueMicros,
            currency: currencyCode,
            adUnitId: widget.idAds,
            adFormat: widget.name,
          );
        },
      ),
      request: const AdRequest(),
    ).load();
  }

  void startRefreshTime() {
    if (widget.refreshSec == 0) {
      return;
    }
    stopRefreshTime();
    print('admob_ads --- banner_ads: startRefreshTime');
    _timerRefresh = Timer.periodic(Duration(seconds: widget.refreshSec), (timer) {
      if (isCanRefreshAd) {
        print('admob_ads --- banner_ads: RefreshSec - ${widget.refreshSec} Done');
        loadAds();
      } else {
        print('admob_ads --- banner_ads: Can not refresh ad isCanRefreshAd = $isCanRefreshAd');
      }
    });
  }

  void stopRefreshTime() {
    _timerRefresh?.cancel();
    _timerRefresh = null;
  }
}
