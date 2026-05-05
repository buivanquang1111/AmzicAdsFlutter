import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_ad_revenue.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:amazic_ads_flutter/admob.dart';
import 'package:flutter/foundation.dart';

class AdjustUtil {
  AdjustUtil._instance();

  static final AdjustUtil instance = AdjustUtil._instance();

  void setUpAdjust({required String adjustToken}) {
    AdjustConfig config = AdjustConfig(
      adjustToken,
      kDebugMode ? AdjustEnvironment.sandbox : AdjustEnvironment.production,
    );
    config.logLevel = AdjustLogLevel.verbose;
    config.defaultTracker = adjustToken;
    Adjust.initSdk(config);
  }

  void trackRevenue({required String? network, required double revenue, required String currency, required String adUnitId, required String adFormat}) {
    print('Adjust: network = $network - revenue = $revenue - currency = $currency\n - adUnitId = $adUnitId - adFormat = $adFormat');

    final num revenueResult = revenue / 1000000;
    AdjustAdRevenue adjustAdRevenue = AdjustAdRevenue('admob_sdk');
    adjustAdRevenue.setRevenue(revenueResult, currency);
    adjustAdRevenue.adRevenueNetwork = network;
    adjustAdRevenue.adRevenueUnit = adUnitId;
    adjustAdRevenue.adRevenuePlacement = adFormat;

    adjustAdRevenue.addPartnerParameter('ad_unit_id', adUnitId);
    adjustAdRevenue.addPartnerParameter('ad_format', adFormat);

    Adjust.trackAdRevenue(adjustAdRevenue);

    if (Admob.instance.eventTrackingAdjust != '') {
      AdjustEvent adjustEvent = AdjustEvent(Admob.instance.eventTrackingAdjust);
      adjustEvent.setRevenue(revenueResult, currency);
      Adjust.trackEvent(adjustEvent);
    }
  }
}
