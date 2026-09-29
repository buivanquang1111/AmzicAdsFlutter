import 'package:flutter/foundation.dart';

/// Gom các cờ cấu hình / trạng thái dùng chung của [Admob] vào một chỗ,
/// thay vì khai báo rải rác nhiều field riêng lẻ trong admob.dart.
///
/// [Admob] vẫn giữ nguyên toàn bộ getter/setter public cũ
/// (isShowAllAds, isUseAdPreloading, jsonIdAdsDefault, ...) và chỉ forward
/// xuống đây, nên phía app dùng thư viện không cần đổi gì.
class AdmobConfig {
  /// enable show full ads
  bool isShowAllAds = true;

  /// true when ads show full screen
  bool isFullScreenAdShowing = false;

  /// token event tracking Adjust
  String eventTrackingAdjust = '';

  /// check when show dialog loading hide ads CollapsibleNative
  final ValueNotifier<bool> isShowDialogLoadingAds = ValueNotifier<bool>(false);

  /// list danh sách các vị trí remote config false khi là Detect Test Ad
  final List<String> detectedTestAds = [];

  void addDetectedTestAd(String adUnitId) {
    if (!detectedTestAds.contains(adUnitId)) {
      detectedTestAds.add(adUnitId);
    }
  }

  bool isAdUnitDetected(String adUnitId) => detectedTestAds.contains(adUnitId);

  /// use ad preload
  bool isUseAdPreloading = false;

  /// number buffer preload
  int numberPreload = 3;

  /// number buffer preload splash
  int numberPreloadSplash = 1;

  /// native after inter (moi dung cho moi man Splash)
  bool isUseNativeAfterInter = false;

  /// json id default
  String jsonIdAdsDefault = '';

  /// native splash
  int timeDelayNativeSplash = 7;
  bool isUseNativeSplash = false;

  /// timeout (giây) chờ 3 task song song (Firebase Remote Config, UMP,
  /// gọi API lấy id quảng cáo) lúc splash. Hết thời gian này mà chưa xong
  /// thì coi như timeout: chuyển màn ngay và không xử lý thêm gì nữa.
  int timeoutScreenSplash = 20;
}
