package com.example.amazic_ads_flutter.app_open_ads

import android.app.Activity
import android.util.Log
import com.example.amazic_ads_flutter.callback.AppOpenCallback
import com.example.amazic_ads_flutter.inter_ads.InterManager
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdValue
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.OnPaidEventListener
import com.google.android.gms.ads.ResponseInfo
import com.google.android.gms.ads.appopen.AppOpenAd
import com.google.android.gms.ads.appopen.AppOpenAdPreloader
import com.google.android.gms.ads.interstitial.InterstitialAdPreloader
import com.google.android.gms.ads.preload.PreloadCallbackV2
import com.google.android.gms.ads.preload.PreloadConfiguration

object AppOpenManager {
    private const val TAG = "AppOpenManager"

    fun loadAppOpenAdPreload(
        idAds: String,
        numberPreload: Int,
        appOpenCallback: AppOpenCallback
    ) {
        Log.d(TAG, "App Open Ad Preload: number ad preloading = $numberPreload")

        val configuration: PreloadConfiguration =
            PreloadConfiguration.Builder(idAds).setBufferSize(numberPreload).build()

        val callback: PreloadCallbackV2 = object : PreloadCallbackV2() {
            override fun onAdFailedToPreload(p0: String, p1: AdError) {
                super.onAdFailedToPreload(p0, p1)
                Log.d(
                    TAG,
                    "App Open Ad Preload: Preload ad $p0, failed to load with error: ${p1.message}"
                )
                appOpenCallback.onAdFailedToLoad(p0, p1.message)
            }

            override fun onAdPreloaded(p0: String, p1: ResponseInfo?) {
                super.onAdPreloaded(p0, p1)
                Log.d(TAG, "App Open Ad Preload: Preload ad for $p0 is available.")
                appOpenCallback.onAdLoaded(p0)
            }

            override fun onAdsExhausted(p0: String) {
                super.onAdsExhausted(p0)
                Log.d(TAG, "App Open Ad Preload: Preload ad for $p0 is exhausted.")

            }
        }

        AppOpenAdPreloader.start(idAds, configuration, callback)
    }

    fun showAppOpenAdPreload(
        activity: Activity,
        idAds: String,
        appOpenCallback: AppOpenCallback
    ) {
        if (!AppOpenAdPreloader.isAdAvailable(idAds)) {
            appOpenCallback.onAdDismissed()
        }

        val ad: AppOpenAd? = AppOpenAdPreloader.pollAd(idAds)
        if (ad != null) {
            ad.onPaidEventListener = object : OnPaidEventListener {
                override fun onPaidEvent(p0: AdValue) {
                    appOpenCallback.onPaidEvent(ad, p0)
                }
            }

            ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                override fun onAdClicked() {
                    super.onAdClicked()
                    appOpenCallback.onAdClicked()
                }

                override fun onAdDismissedFullScreenContent() {
                    super.onAdDismissedFullScreenContent()
                    appOpenCallback.onAdDismissed()
                }

                override fun onAdFailedToShowFullScreenContent(p0: AdError) {
                    super.onAdFailedToShowFullScreenContent(p0)
                    appOpenCallback.onAdFailedToShow(p0.message)
                }

                override fun onAdImpression() {
                    super.onAdImpression()
                    appOpenCallback.onAdImpression()
                }

                override fun onAdShowedFullScreenContent() {
                    super.onAdShowedFullScreenContent()
                    appOpenCallback.onAdShowed()
                }
            }
            ad.show(activity)
        } else {
            appOpenCallback.onAdDismissed()
        }
    }

    fun destroy(idAds: String){
        AppOpenAdPreloader.destroy(idAds)
    }

    fun isAdAvailable(idAds: String): Boolean{
        Log.d(TAG, "App Open Ad Preload: isAdAvailable = ${AppOpenAdPreloader.isAdAvailable(idAds)}, idAds = $idAds")
        return AppOpenAdPreloader.isAdAvailable(idAds)
    }

}