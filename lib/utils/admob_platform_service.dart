import '../amazic_ads_flutter_platform_interface.dart';

/// Gói lại các lời gọi sang platform channel (Android/iOS) mà [Admob] cần
/// dùng: lấy platform version, kết quả UMP consent, trạng thái mạng.
///
/// [Admob] vẫn giữ nguyên các hàm public cũ (getPlatformVersion,
/// getConsentResult, isNetworkActive) và chỉ forward xuống đây.
class AdmobPlatformService {
  AdmobPlatformService._();

  static final AdmobPlatformService instance = AdmobPlatformService._();

  Future<String?> getPlatformVersion() {
    return AmazicAdsFlutterPlatform.instance.getPlatformVersion();
  }

  Future<bool?> getConsentResult() async {
    final canRequest = await AmazicAdsFlutterPlatform.instance.getConsentResult();
    print('admob_ads --- ump: getConsentResult - $canRequest');
    return canRequest;
  }

  Future<bool?> isNetworkActive() async {
    final isConnected = await AmazicAdsFlutterPlatform.instance.isNetworkActive();
    print('admob_ads --- have_internet: $isConnected');
    return isConnected;
  }
}
