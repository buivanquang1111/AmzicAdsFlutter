import 'package:flutter_test/flutter_test.dart';
import 'package:amazic_ads_flutter/amazic_ads_flutter.dart';
import 'package:amazic_ads_flutter/amazic_ads_flutter_platform_interface.dart';
import 'package:amazic_ads_flutter/amazic_ads_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAmazicAdsFlutterPlatform
    with MockPlatformInterfaceMixin
    implements AmazicAdsFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AmazicAdsFlutterPlatform initialPlatform = AmazicAdsFlutterPlatform.instance;

  test('$MethodChannelAmazicAdsFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAmazicAdsFlutter>());
  });

  test('getPlatformVersion', () async {
    AmazicAdsFlutter amazicAdsFlutterPlugin = AmazicAdsFlutter();
    MockAmazicAdsFlutterPlatform fakePlatform = MockAmazicAdsFlutterPlatform();
    AmazicAdsFlutterPlatform.instance = fakePlatform;

    expect(await amazicAdsFlutterPlugin.getPlatformVersion(), '42');
  });
}
