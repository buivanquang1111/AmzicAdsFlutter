import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/shimmer/shimmer_banner_ads.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAds extends StatefulWidget {
  final String idAds;
  final Function()? onAdLoaded;
  final Function()? onAdFailedToLoad;
  final Function()? onAdImpression;
  final Function()? onAdClicked;
  final Function()? onAdDisable;
  final bool config;

  const BannerAds({
    super.key,
    required this.idAds,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdImpression,
    this.onAdClicked,
    this.onAdDisable,
    required this.config,
  });

  @override
  State<BannerAds> createState() => _BannerAdsState();
}

class _BannerAdsState extends State<BannerAds> {
  BannerAd? _bannerAd;
  bool _isLoading = false;
  bool _shouldHide = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadAds();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
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
      widget.onAdDisable?.call();
      return;
    }
    if (widget.config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
      print('admob_ads --- banner_ads: hide banner');
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
          ad.dispose();
          setState(() {
            _bannerAd = null;
            _isLoading = false;
            _shouldHide = true;
          });
          widget.onAdFailedToLoad?.call();
        },
        onAdImpression: (ad) {
          print('admob_ads --- banner_ads: onAdImpression');
          widget.onAdImpression?.call();
        },
        onAdClicked: (ad) {
          print('admob_ads --- banner_ads: onAdClicked');
          widget.onAdClicked?.call();
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
        },
      ),
      request: const AdRequest(),
    ).load();
  }
}
