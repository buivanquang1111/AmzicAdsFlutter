# amazic_ads_flutter

A new Flutter plugin project.

## khởi tạo Adjust tai main()
```html
AdjustUtil.instance.setUpAdjust(adjustToken: AdsManager.adjustToken);
```

## khởi tạo ads tai Splash
```dart
void init() async{
  await Admob.instance.init(
    linkServer: null,
    appId: null,
    packageName: null,
    navigatorKey: navigatorKey,
    nameIddAdsResume: 'resume_wb',
    isShowWelComeScreenAfterAppOpenAds: true,
    nameIdAdsAppOpenSplash: 'open_splash',
    nameIdAdsInterSplash: 'inter_splash',
    nameConfigAppOpenSplash: 'open_splash',
    nameConfigInterSplash: 'inter_splash',
    nameRateAoa: 'rate_aoa_inter_splash',
    onNext: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    },
    nameIntervalBetweenInter: 'interval_between_interstitial',
    nameIntervalFromStart: 'interval_interstitial_from_start',
    nameIntervalInterAll: 'interval_inter_all',
    onStartLoadBanner: () {
      setState(() {});
    },
    remoteConfigKeys: [
      RemoteConfigKey(name: 'show_ads', defaultValue: true, valueType: bool),
      RemoteConfigKey(name: 'banner_ads', defaultValue: true, valueType: bool),
      RemoteConfigKey(name: 'collap_reload_interval', defaultValue: 10, valueType: int),
      RemoteConfigKey(name: 'collapse_banner', defaultValue: true, valueType: bool),
      RemoteConfigKey(name: 'inter_ads', defaultValue: true, valueType: bool),
      RemoteConfigKey(name: 'inter_splash', defaultValue: true, valueType: bool),
      RemoteConfigKey(name: 'interval_between_interstitial', defaultValue: 20, valueType: int),
      RemoteConfigKey(name: 'interval_inter_all', defaultValue: 30, valueType: int),
      RemoteConfigKey(name: 'interval_interstitial_from_start', defaultValue: 5, valueType: int),
      RemoteConfigKey(name: 'interval_reload_native', defaultValue: 5, valueType: int),
      RemoteConfigKey(name: 'native_ads', defaultValue: true, valueType: bool),
      RemoteConfigKey(name: 'open_splash', defaultValue: true, valueType: bool),
      RemoteConfigKey(name: 'rate_aoa_inter_splash', defaultValue: '0_100', valueType: String),
      RemoteConfigKey(name: 'resume_wb', defaultValue: true, valueType: bool),
    ],
  );
}
```
## Banner ad
```html
BannerAds(
    idAds: 'ca-app-pub-3940256099942544/6300978111',
    config: true,
    name: 'banner_all',
),
```

