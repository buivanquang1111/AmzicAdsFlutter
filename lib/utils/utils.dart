import 'package:amazic_ads_flutter/admob.dart';
import 'package:amazic_ads_flutter/dialog/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

bool _isDialogShow = false;

showLoadingDialog({required BuildContext context}) {
  print('admob_ads --- showLoadingDialog');
  _isDialogShow = true;
  Admob.instance.showLoading();
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return LoadingDialog();
    },
  );
}

closeLoadingDialog({required BuildContext context}) {
  if (_isDialogShow && Navigator.canPop(context)) {
    print('admob_ads --- closeLoadingDialog');
    Navigator.of(context, rootNavigator: true).pop();
    _isDialogShow = false;
    Admob.instance.hideLoading();
  }
}

logInterMediation({required InterstitialAd ad, required String nameAds}){
  /// ====== LOG WINNER ======
  final info = ad.responseInfo;
  final winner = info?.loadedAdapterResponseInfo;
  print('=== MEDIATION WINNER $nameAds ===');
  print('Network: ${winner?.adSourceName}');
  print('Class: ${winner?.adapterClassName}');
  print('AdSource ID: ${winner?.adSourceId}');
  print('Latency: ${winner?.latencyMillis} ms');
  print('=========================');
  /// ====== LOG FULL WATERFALL ======
  final allResponses = info?.adapterResponses ?? [];
  print('=== FULL WATERFALL $nameAds ===');
  for (final adapter in allResponses) {
    print('Adapter: ${adapter.adSourceName}');
    print('  Class: ${adapter.adapterClassName}');
    print('  Latency: ${adapter.latencyMillis} ms');
    print('  Description: ${adapter.description}');
  }
  print('=======================');
}

logNativeMediation({required Ad ad, required String nameAds}){
  /// ====== LOG WINNER ======
  final info = ad.responseInfo;
  final winner = info?.loadedAdapterResponseInfo;
  print('=== MEDIATION WINNER $nameAds ===');
  print('Network: ${winner?.adSourceName}');
  print('Class: ${winner?.adapterClassName}');
  print('AdSource ID: ${winner?.adSourceId}');
  print('Latency: ${winner?.latencyMillis} ms');
  print('=========================');
  /// ====== LOG FULL WATERFALL ======
  final allResponses = info?.adapterResponses ?? [];
  print('=== FULL WATERFALL $nameAds ===');
  for (final adapter in allResponses) {
    print('Adapter: ${adapter.adSourceName}');
    print('  Class: ${adapter.adapterClassName}');
    print('  Latency: ${adapter.latencyMillis} ms');
    print('  Description: ${adapter.description}');
  }
  print('=======================');
}
