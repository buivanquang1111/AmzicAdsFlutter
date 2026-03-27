package com.example.amazic_ads_flutter.inter_ads

import android.app.Activity
import android.content.Context
import android.util.Log
import com.example.amazic_ads_flutter.callback.InterCallback
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdValue
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.OnPaidEventListener
import com.google.android.gms.ads.ResponseInfo
import com.google.android.gms.ads.interstitial.InterstitialAd
import com.google.android.gms.ads.interstitial.InterstitialAdPreloader
import com.google.android.gms.ads.preload.PreloadCallbackV2
import com.google.android.gms.ads.preload.PreloadConfiguration

object InterManager {

    private const val TAG = "InterManager"

    fun loadInterAdPreload(
        idAds: String,
        numberPreload: Int,
        interCallback: InterCallback
    ) {
        Log.d(TAG, "INTER Ad Preload: number ad preloading = $numberPreload")

        val configuration: PreloadConfiguration =
            PreloadConfiguration.Builder(idAds).setBufferSize(numberPreload).build()

        val callback: PreloadCallbackV2 = object : PreloadCallbackV2() {
            override fun onAdFailedToPreload(p0: String, p1: AdError) {
                super.onAdFailedToPreload(p0, p1)
                Log.d(
                    TAG,
                    "INTER Ad Preload: Preload ad $p0, failed to load with error: ${p1.message}"
                );
                interCallback.onAdFailedToLoad(p0, p1.message)
            }

            override fun onAdPreloaded(p0: String, p1: ResponseInfo?) {
                super.onAdPreloaded(p0, p1)
                Log.d(TAG, "INTER Ad Preload: Preload ad for $p0 is available.")
                interCallback.onAdLoaded(p0)
            }

            override fun onAdsExhausted(p0: String) {
                super.onAdsExhausted(p0)
                Log.d(TAG, "INTER Ad Preload: Preload ad for $p0 is exhausted.")
            }
        }

        InterstitialAdPreloader.start(idAds, configuration, callback)
    }

    fun showInterAdPreload(
        activity: Activity,
        idAds: String,
        interCallback: InterCallback,
    ) {
        if (!InterstitialAdPreloader.isAdAvailable(idAds)) {
            interCallback.onAdDismissed()
        }

        val ad: InterstitialAd? = InterstitialAdPreloader.pollAd(idAds)

        if (ad != null) {
            ad.onPaidEventListener = object : OnPaidEventListener{
                override fun onPaidEvent(p0: AdValue) {
                    interCallback.onPaidEvent(ad, p0)
                }
            }
            ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                override fun onAdClicked() {
                    super.onAdClicked()
                    interCallback.onAdClicked()
                }

                override fun onAdDismissedFullScreenContent() {
                    super.onAdDismissedFullScreenContent()
                    interCallback.onAdDismissed()
                }

                override fun onAdFailedToShowFullScreenContent(p0: AdError) {
                    super.onAdFailedToShowFullScreenContent(p0)
                    interCallback.onAdFailedToShow(p0.message)
                }

                override fun onAdImpression() {
                    super.onAdImpression()
                    interCallback.onAdImpression()
                }

                override fun onAdShowedFullScreenContent() {
                    super.onAdShowedFullScreenContent()
                    interCallback.onAdShowed()
                }
            }
            ad.show(activity)
        } else {
            interCallback.onAdDismissed()
        }

    }

    fun destroy(idAds: String) {
        InterstitialAdPreloader.destroy(idAds)
    }

}