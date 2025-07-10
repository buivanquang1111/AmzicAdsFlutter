import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/shimmer/shimmer_native_ads.dart';
import 'package:amazic_ads_flutter/ump/consent_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAds extends StatefulWidget {
  final String idAds;
  final bool config;
  final double height;
  final String factoryId;
  final Function()? onAdLoaded;
  final Function()? onAdFailedToLoad;
  final Function()? onAdImpression;
  final Function()? onAdClicked;

  const NativeAds({
    super.key,
    required this.idAds,
    required this.config,
    required this.height,
    required this.factoryId,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdImpression,
    this.onAdClicked,
  });

  @override
  State<NativeAds> createState() => _NativeAdsState();
}

class _NativeAdsState extends State<NativeAds> {
  NativeAd? _nativeAd;
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
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldHide) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return ShimmerNativeAds(height: widget.height);
    }

    if (_nativeAd != null) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: widget.height,
        child: AdWidget(ad: _nativeAd!),
      );
    }

    return const SizedBox.shrink();
  }

  loadAds() async {
    if (widget.config == false ||
        ConsentManager.instance.canRequestAds == false ||
        Admob.instance.isShowAllAds == false ||
        (await Admob.instance.isNetworkActive()) == false) {
      print('admob_ads --- native_ads: hide native');
      setState(() {
        _shouldHide = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _shouldHide = false;
    });
    print('admob_ads --- native_ads: start request');
    _nativeAd = NativeAd(
      adUnitId: widget.idAds,
      factoryId: widget.factoryId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('admob_ads --- native_ads: onAdLoaded');
          setState(() {
            _isLoading = false;
          });
          widget.onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          print('admob_ads --- native_ads: onAdFailedToLoad');
          setState(() {
            _nativeAd = null;
            _isLoading = false;
            _shouldHide = true;
          });
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
          widget.onAdImpression?.call();
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
        onAdClicked: (ad) {
          print('admob_ads --- native_ads: onAdClicked');
          widget.onAdClicked?.call();
        },
      ),
      request: const AdRequest(),
    )..load();
  }
}
