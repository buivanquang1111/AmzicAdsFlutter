import 'package:amazic_ads_flutter/amazic_ads_flutter.dart';
import 'package:amazic_ads_flutter/shimmer/shimmer_banner_ads.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
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

  const CollapseBannerAds({
    super.key,
    required this.idAds,
    required this.type,
    required this.config,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdImpression,
    this.onAdClicked,
    this.onAdDisable,
  });

  @override
  State<CollapseBannerAds> createState() => CollapseBannerAdsState();
}

class CollapseBannerAdsState extends State<CollapseBannerAds> {
  BannerAd? _bannerAd;
  bool _isLoading = false;
  bool _shouldHide = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadCollapseAds();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _bannerAd?.dispose();
  }

  Future<void> closeCollapse() async {
    _bannerAd?.dispose();
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

    if (widget.config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
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
          print('admob_ads --- collapse_banner: onAdLoaded');
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoading = false;
          });
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
          widget.onAdFailedToLoad?.call();
        },
        onAdImpression: (ad) {
          print('admob_ads --- collapse_banner: onAdImpression');
          widget.onAdImpression?.call();
        },
        onAdClicked: (ad) {
          print('admob_ads --- collapse_banner: onAdClicked');
          widget.onAdClicked?.call();
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
        },
      ),
      request: adRequest,
    ).load();
  }
}
