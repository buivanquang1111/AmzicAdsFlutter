package com.example.amazic_ads_flutter.reward_ads

import android.app.Activity
import android.util.Log
import com.example.amazic_ads_flutter.callback.RewardCallback
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdValue
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.OnPaidEventListener
import com.google.android.gms.ads.ResponseInfo
import com.google.android.gms.ads.preload.PreloadCallbackV2
import com.google.android.gms.ads.preload.PreloadConfiguration
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdPreloader

object RewardManager {
    private const val TAG = "RewardManager"

    fun loadRewardAdPreload(
        idAds: String,
        numberPreload: Int,
        rewardCallback: RewardCallback
    ) {
        Log.d(TAG, "Reward Ad Preload: number ad preloading = $numberPreload")

        val configuration: PreloadConfiguration =
            PreloadConfiguration.Builder(idAds).setBufferSize(numberPreload).build()

        val callback: PreloadCallbackV2 = object : PreloadCallbackV2(){
            override fun onAdFailedToPreload(p0: String, p1: AdError) {
                super.onAdFailedToPreload(p0, p1)
                Log.d(
                    TAG,
                    "Reward Ad Preload: Preload ad $p0, failed to load with error: ${p1.message}"
                )
                rewardCallback.onAdFailedToLoad(p0, p1.message)
            }

            override fun onAdPreloaded(p0: String, p1: ResponseInfo?) {
                super.onAdPreloaded(p0, p1)
                Log.d(TAG, "Reward Ad Preload: Preload ad for $p0 is available.")
                rewardCallback.onAdLoaded(p0)
            }

            override fun onAdsExhausted(p0: String) {
                super.onAdsExhausted(p0)
                Log.d(TAG, "Reward Ad Preload: Preload ad for $p0 is exhausted.")

            }
        }

        RewardedAdPreloader.start(idAds,configuration,callback)
    }

    fun showRewardAdPreload(
        activity: Activity,
        idAds: String,
        rewardCallback: RewardCallback,
    ){
        if(!RewardedAdPreloader.isAdAvailable(idAds)){
            rewardCallback.onAdDismissed()
        }

        val ad: RewardedAd? = RewardedAdPreloader.pollAd(idAds)

        if(ad != null){
            ad.onPaidEventListener = object : OnPaidEventListener{
                override fun onPaidEvent(p0: AdValue) {
                    rewardCallback.onPaidEvent(ad, p0)
                }
            }

            ad.fullScreenContentCallback = object : FullScreenContentCallback(){
                override fun onAdClicked() {
                    super.onAdClicked()
                    rewardCallback.onAdClicked()
                }

                override fun onAdDismissedFullScreenContent() {
                    super.onAdDismissedFullScreenContent()
                    rewardCallback.onAdDismissed()
                }

                override fun onAdFailedToShowFullScreenContent(p0: AdError) {
                    super.onAdFailedToShowFullScreenContent(p0)
                    rewardCallback.onAdFailedToShow(p0.message)
                }

                override fun onAdImpression() {
                    super.onAdImpression()
                    rewardCallback.onAdImpression()
                }

                override fun onAdShowedFullScreenContent() {
                    super.onAdShowedFullScreenContent()
                    rewardCallback.onAdShowed()
                }
            }
            ad.show(activity) { rewardItem ->
                rewardCallback.onUserEarned()
            }
        }else{
            rewardCallback.onAdDismissed()
        }
    }

    fun destroy(idAds: String){
        RewardedAdPreloader.destroy(idAds)
    }

    fun isAdAvailable(idAds: String): Boolean{
        Log.d(TAG, "Reward Ad Preload: isAdAvailable = ${RewardedAdPreloader.isAdAvailable(idAds)}, idAds = $idAds")
        return RewardedAdPreloader.isAdAvailable(idAds)
    }
}