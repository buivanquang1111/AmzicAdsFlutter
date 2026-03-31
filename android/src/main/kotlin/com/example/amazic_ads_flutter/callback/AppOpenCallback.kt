package com.example.amazic_ads_flutter.callback

import com.google.android.gms.ads.AdValue
import com.google.android.gms.ads.appopen.AppOpenAd

interface AppOpenCallback {
    fun onAdLoaded(adUnit: String?)
    fun onAdFailedToLoad(adUnit: String?, message: String)
    fun onAdClicked()
    fun onAdDismissed()
    fun onAdFailedToShow(message: String)
    fun onAdImpression()
    fun onAdShowed()
    fun onPaidEvent(ad: AppOpenAd, adValue: AdValue)
}