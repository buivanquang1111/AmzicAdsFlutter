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

## CollapseBanner ad
khởi tạo
```html
CollapseBannerAds? collapseBannerAds;
var canClick = true;
final collapseKey = GlobalKey<CollapseBannerAdsState>();
    @override
    void initState() {
        super.initState();
        collapseBannerAds = CollapseBannerAds(
        key: collapseKey,
        idAds: 'ca-app-pub-3940256099942544/2014213617',
        type: CollapseBannerType.collapsible_bottom,
        config: true,
        refreshSec: 5,
        name: 'collapse_banner_all',
        );
    }
```
ẩn Collapse ads trước khi chuyển qua màn mới
```html
Future<void> dismissCollapse() async {
    if (collapseBannerAds == null) {
      return;
    }
    canClick = false;
    await collapseKey.currentState?.closeCollapse();
    collapseKey.currentState?.setIsOnScreenShowCollapse(isOnScreenShowCollapse: false);
    collapseKey.currentState?.setIsCanRefreshAd(isCan: false);
    await Future.delayed(const Duration(milliseconds: 800));
    canClick = true;
  }
```
khi quay lại từ màn sau về màn show collapse banner gọi thêm
bắt buộc phải gọi setIsOnScreenShowCollapse trước setIsCanRefreshAd
```html
collapseKey.currentState?.setIsOnScreenShowCollapse(isOnScreenShowCollapse: true);
collapseKey.currentState?.setIsCanRefreshAd(isCan: true);
```

ví dụ
```html
await dismissCollapse();
Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => DetailScreen()),
    ).then((value) {
        collapseKey.currentState?.setIsOnScreenShowCollapse(isOnScreenShowCollapse: true);
        collapseKey.currentState?.setIsCanRefreshAd(isCan: true);
});
```

với trường hợp có màn WelcomeBack, khởi tạo hàm ở initState
```html
 Admob.instance.appLifecycleReactor?.setCloseCollapseBannerWelComeBack(
    onCloseCollapse: () async {
        await collapseKey.currentState?.closeCollapse();
        collapseKey.currentState?.setIsCanRefreshAd(isCan: false);
        await Future.delayed(const Duration(milliseconds: 800));
    },
);
Admob.instance.appLifecycleReactor?.setReloadCollapseBannerCloseWelComeBack(
    omReloadCollapse: () {
        collapseKey.currentState?.setIsCanRefreshAd(isCan: true);
    },
);
```
Trường hợp isShowWelComeScreenAfterAppOpenAds: false không cần thêm gì
Trường hợp isShowWelComeScreenAfterAppOpenAds: true gọi thêm ở nút Continue (quay về màn đang dùng)
```html
Admob.instance.appLifecycleReactor?.onReloadCollapseBanner?.call();
```

## Banner ad
```html
BannerAds(
    idAds: 'ca-app-pub-3940256099942544/6300978111',
    config: true,
    name: 'banner_all',
),
```

## Native ad
```html
NativeAds(
    idAds: 'ca-app-pub-3940256099942544/2247696110',
    config: true,
    height: 300,
    factoryId: 'native_ad',
    refreshSec: 5,
    name: 'native_all',
),
```

## Preload Native Ad
call load ads
```html
 NativeAdManager().preloadAd(
      adUnitId: CallApi.instance.getFirstIDByName('native_language'),
      config: true,
      nameIdAds: 'native_language',
      factoryId: 'native_ad',
      onAdLoaded: () {
      },
      onAdFailed: (error) {
      },
    );
```
call show ads
```html
NativeAdManager().showAd(config: false, nameIdAds: 'native_language', height: 300),
```

## Inter ad
```html
Admob.instance.loadAndShowInterInterval(
    navigatorKey: navigatorKey,
    idAds: 'ca-app-pub-3940256099942544/1033173712',
    config: true,
    isInterAll: true,
    name: 'inter_all',
    onAdDisable: () {

    },
    onAdFailedToLoad: () {

    },
    onAdFailedToShow: () {

    },
    onAdDismiss: () {

    },
);
```

## Reward ad
```html
Admob.instance.loadAndShowRewardAds(
    navigatorKey: navigatorKey,
    idAds: 'ca-app-pub-3940256099942544/5224354917',
    config: true,
    name: 'reward_all',
    onAdDisable: () {
    
    },
    onAdDismiss: () {
                            
    },
);
```

## Reward ad show with count
cần load trước khi dùng
```html
 Admob.instance.loadRewardAdConsecutive(
      idAds: 'ca-app-pub-3940256099942544/5224354917',
      config: true,
);
```
call show
```html
Admob.instance.showRewardConsecutive(
    idAds: 'ca-app-pub-3940256099942544/5224354917',
    config: true,
    count: 2,
    name: 'reward2_all',
    onCompleted: () {
                            
    },
);
```


