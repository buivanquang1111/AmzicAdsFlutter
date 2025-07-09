import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amazic_ads_flutter/amazic_ads_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelAmazicAdsFlutter platform = MethodChannelAmazicAdsFlutter();
  const MethodChannel channel = MethodChannel('amazic_ads_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
