import 'dart:async';

import 'package:amazic_ads_flutter/shimmer/shimmer_native_ads.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../admob.dart';
import '../ump/consent_manager.dart';
import '../utils/adjust_util.dart';
import '../utils/event_log.dart';

class CollapsibleNativeAds extends StatefulWidget {
  final String idAds;
  final bool config;
  final String factoryId;
  final String smallFactoryId;
  final Widget? shimmer;
  final double bigHeight;
  final double smallHeight;
  final Function()? onAdLoaded;
  final Function()? onAdFailedToLoad;
  final Function()? onAdImpression;
  final Function()? onAdClicked;
  final int refreshSec;
  final String name;
  final bool isAlwaysShowCollapse; //check có cho reload sổ collapse lên

  const CollapsibleNativeAds({
    super.key,
    required this.idAds,
    required this.config,
    required this.factoryId,
    required this.smallFactoryId,
    required this.refreshSec,
    required this.name,
    this.bigHeight = 268,
    this.smallHeight = 130,
    this.shimmer,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdImpression,
    this.onAdClicked,
    this.isAlwaysShowCollapse = false,
  });

  @override
  State<CollapsibleNativeAds> createState() => _CollapsibleNativeAdsState();
}

class _CollapsibleNativeAdsState extends State<CollapsibleNativeAds> with WidgetsBindingObserver {
  NativeAd? _nativeAd;
  bool _isLoading = false;
  bool _isExpanded = true;
  bool _shouldHide = false;
  bool _isCurrentAdLoadedAsBig = true; //kiểm tra quảng cáo đang hiển thị là dạng to hay nhỏ

  Timer? _timerRefresh;

  //show overlay ads
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  // Controller để điều khiển hiệu ứng cuộn
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadAd();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nativeAd?.dispose();
    _removeOverlay();
    stopRefreshTime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      print('admob_ads --- collapsible_native: ${widget.name} AppLifecycleState.paused');
      stopRefreshTime();
    } else if (state == AppLifecycleState.resumed) {
      print('admob_ads --- collapsible_native: ${widget.name} AppLifecycleState.resumed');
      startRefreshTime();
    }
  }

  void reloadNow() {
    stopRefreshTime();
    loadAd();
  }

  // Hàm tạo lớp phủ (Overlay) để có thể Click toàn bộ vùng 320px
  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        double targetHeight = _isExpanded ? widget.bigHeight : widget.smallHeight;
        return ValueListenableBuilder<bool>(
          valueListenable: Admob.instance.isShowDialogLoadingAds,
          builder: (context, value, child) {
            if (value) return const SizedBox.shrink();

            return TweenAnimationBuilder(
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              tween: Tween<double>(end: targetHeight),
              builder: (context, animHeight, child) {
                // Tính toán offset dựa trên chiều cao đang chạy animation
                // Khi animHeight tăng, offsetY sẽ âm nhiều hơn -> Đẩy ad vươn lên trên
                double offsetY = widget.smallHeight - animHeight;

                return Positioned(
                  width: MediaQuery.of(context).size.width,
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    // Đẩy quảng cáo lên trên sao cho đáy của nó dính vào đáy của Widget mục tiêu
                    offset: Offset(0, offsetY),
                    child: Material(color: Colors.transparent, child: _buildAdContent(animHeight)),
                  ),
                );
              },
            );
          },
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  Widget _buildAdContent(double currentHeight) {
    double renderHeight = widget.isAlwaysShowCollapse
        ? widget.bigHeight
        : (_isCurrentAdLoadedAsBig ? widget.bigHeight : widget.smallHeight);
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          height: currentHeight,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            boxShadow: [
              if (currentHeight > widget.smallHeight)
                BoxShadow(color: Colors.black12, blurRadius: 1),
            ],
          ),
          child: OverflowBox(
            minHeight: renderHeight,
            maxHeight: renderHeight,
            alignment: Alignment.bottomCenter,
            child: AdWidget(key: ValueKey('${widget.name}_${_nativeAd.hashCode}'), ad: _nativeAd!),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Visibility(
            visible: _isExpanded ? true : false,
            child: GestureDetector(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
                _updateOverlay();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10, top: 5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                ),
                child: Icon(
                  _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldHide) {
      return const SizedBox.shrink();
    }

    if (_isLoading) return widget.shimmer ?? ShimmerNativeAds(height: widget.smallHeight);

    if (_nativeAd != null) {
      return VisibilityDetector(
        key: Key('${widget.name}_${_nativeAd.hashCode}'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction == 0) {
            print('admob_ads --- collapsible_native: ${widget.name} Hidden');
            stopRefreshTime();
          } else {
            print('admob_ads --- collapsible_native: ${widget.name} Show');
            startRefreshTime();
          }
        },
        child: CompositedTransformTarget(
          link: _layerLink,
          child: SizedBox(width: double.infinity, height: widget.smallHeight),
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

  loadAd() async {
    bool? isNetwork = await Admob.instance.isNetworkActive();
    if (!await canShowAds()) {
      print('admob_ads --- collapsible_native: ${widget.name} Hide native Check condition');
      EventLog.logEvent(
        '${widget.name}_not_request',
        parameters: {
          'config': widget.config,
          'ump': ConsentManager.instance.canRequestAds,
          'isShowAllAds': Admob.instance.isShowAllAds,
          'isNetwork': isNetwork == true,
        },
      );
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

    print('admob_ads --- collapsible_native: ${widget.name} start request');
    EventLog.logEvent('${widget.name}_request');
    EventLog.logEvent('${widget.name}_request_first');

    String currentFactoryId = widget.isAlwaysShowCollapse
        ? widget.factoryId
        : (_isExpanded ? widget.factoryId : widget.smallFactoryId);

    _nativeAd = NativeAd(
      adUnitId: widget.idAds,
      factoryId: currentFactoryId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('admob_ads --- collapsible_native: ${widget.name} onAdLoaded');
          EventLog.logEvent('${widget.name}_load');
          if (mounted) {
            _removeOverlay();
            setState(() {
              _isLoading = false;
              if (!widget.isAlwaysShowCollapse) {
                _isCurrentAdLoadedAsBig = _isExpanded;
              }
            });
            _showOverlay();
          }
          widget.onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          print('admob_ads --- collapsible_native: ${widget.name} onAdFailedToLoad');
          EventLog.logEvent('${widget.name}_fail', parameters: {'error': error.message});
          if (mounted) {
            setState(() {
              _nativeAd = null;
              _isLoading = false;
              _shouldHide = true;
            });
          }
          _removeOverlay();
          startRefreshTime();
          widget.onAdFailedToLoad?.call();
        },
        onAdOpened: (ad) {
          print('admob_ads --- collapsible_native: ${widget.name} onAdOpened');
        },
        onAdWillDismissScreen: (ad) {
          print('admob_ads --- collapsible_native: ${widget.name} onAdWillDismissScreen');
        },
        onAdClosed: (ad) {
          print('admob_ads --- collapsible_native: ${widget.name} onAdClosed');
        },
        onAdImpression: (ad) {
          print('admob_ads --- collapsible_native: ${widget.name} onAdImpression');
          EventLog.logEvent('${widget.name}_impression');
          startRefreshTime();
          widget.onAdImpression?.call();
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          print(
            'admob_ads --- collapsible_native: ${widget.name} onPaidEvent - valueMicros= $valueMicros - currencyCode= $currencyCode',
          );
          AdjustUtil.instance.trackRevenue(
            network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
            revenue: valueMicros,
            currency: currencyCode,
            adUnitId: widget.idAds,
            adFormat: widget.name,
          );
        },
        onAdClicked: (ad) {
          print('admob_ads --- collapsible_native: ${widget.name} onAdClicked');
          EventLog.logEvent('${widget.name}_click');
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
    print('admob_ads --- collapsible_native: ${widget.name} startRefreshTime');
    _timerRefresh = Timer.periodic(Duration(seconds: widget.refreshSec), (timer) {
      print(
        'admob_ads --- collapsible_native: ${widget.name} RefreshSec - ${widget.refreshSec} Done',
      );
      loadAdsQuietly();
    });
  }

  void stopRefreshTime() {
    print('admob_ads --- collapsible_native: ${widget.name} stopRefreshTime');
    _timerRefresh?.cancel();
    _timerRefresh = null;
  }

  loadAdsQuietly() async {
    bool? isNetwork = await Admob.instance.isNetworkActive();
    if (!await canShowAds()) {
      print('admob_ads --- collapsible_native: ${widget.name} Quietly - hide native');
      EventLog.logEvent(
        '${widget.name}_not_request',
        parameters: {
          'config': widget.config,
          'ump': ConsentManager.instance.canRequestAds,
          'isShowAllAds': Admob.instance.isShowAllAds,
          'isNetwork': isNetwork == true,
        },
      );
      return;
    }
    late NativeAd tempAd;

    EventLog.logEvent('${widget.name}_request');

    String currentFactoryId = widget.isAlwaysShowCollapse
        ? widget.factoryId
        : (_isExpanded ? widget.factoryId : widget.smallFactoryId);

    tempAd = NativeAd(
      adUnitId: widget.idAds,
      factoryId: currentFactoryId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          final oldAd = _nativeAd;
          final newAd = ad as NativeAd;

          EventLog.logEvent('${widget.name}_load');

          if (mounted) {
            _removeOverlay();

            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              setState(() {
                _nativeAd = newAd;
                _isLoading = false;
                _shouldHide = false;

                if (widget.isAlwaysShowCollapse) {
                  _isExpanded = true;
                } else {
                  _isCurrentAdLoadedAsBig = _isExpanded;
                }
              });
              _showOverlay();
            });
          }

          Future.microtask(() {
            oldAd?.dispose();
          });
          print('admob_ads --- collapsible_native: ${widget.name} Quietly - onAdLoaded $_nativeAd');
        },
        onAdFailedToLoad: (ad, error) {
          print(
            'admob_ads --- natcollapsible_nativeive_ads: ${widget.name} Quietly - onAdFailedToLoad',
          );
          EventLog.logEvent('${widget.name}_fail', parameters: {'error': error.message});
          _removeOverlay();
          ad.dispose();
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          print('admob_ads --- collapsible_native: ${widget.name} Quietly - onPaidEvent');
          AdjustUtil.instance.trackRevenue(
            network: ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName,
            revenue: valueMicros,
            currency: currencyCode,
            adUnitId: widget.idAds,
            adFormat: widget.name,
          );
        },
        onAdImpression: (ad) {
          print('admob_ads --- collapsible_native: ${widget.name} Quietly - onAdImpression');
          EventLog.logEvent('${widget.name}_impression');
        },
        onAdClicked: (ad) {
          print('admob_ads --- collapsible_native: ${widget.name} Quietly - onAdClicked');
          EventLog.logEvent('${widget.name}_click');
        },
      ),
      request: const AdRequest(),
    );
    tempAd.load();
  }
}
