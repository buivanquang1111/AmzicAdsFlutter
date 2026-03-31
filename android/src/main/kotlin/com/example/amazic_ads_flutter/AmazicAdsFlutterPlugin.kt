package com.example.amazic_ads_flutter

import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import android.preference.PreferenceManager
import android.util.Log
import com.example.amazic_ads_flutter.util.NetworkUtil

import com.example.amazic_ads_flutter.ads_banner.BannerAdsPlatformViewFactory;
import com.example.amazic_ads_flutter.app_open_ads.AppOpenManager
import com.example.amazic_ads_flutter.callback.AppOpenCallback
import com.example.amazic_ads_flutter.callback.InterCallback
import com.example.amazic_ads_flutter.inter_ads.InterManager
import com.google.android.gms.ads.AdValue
import com.google.android.gms.ads.appopen.AppOpenAd
import com.google.android.gms.ads.interstitial.InterstitialAd
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AmazicAdsFlutterPlugin */
class AmazicAdsFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var bannerAdsMethod: MethodChannel
    private lateinit var channel: MethodChannel
    private lateinit var interChannel: MethodChannel
    private lateinit var appOpenChannel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "amazic_ads_flutter")
        channel.setMethodCallHandler(this)

        context = flutterPluginBinding.applicationContext

        bannerAdsMethod =
            MethodChannel(flutterPluginBinding.binaryMessenger, "banner_ads_detect_test_ads")
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory(
                "banner_view_platform",
                BannerAdsPlatformViewFactory(context, bannerAdsMethod)
            )
        interChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "amazic_ads_inter")
        interChannel.setMethodCallHandler(this)

        appOpenChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "amazic_ads_app_open")
        appOpenChannel.setMethodCallHandler(this)

    }

    private fun sendInterEvent(method: String, adId: String, extras: Map<String, Any?>? = null) {
        val data = mutableMapOf<String, Any?>("id" to adId)
        extras?.let { data.putAll(it) }
        activity?.runOnUiThread { interChannel.invokeMethod(method, data) }
    }

    private fun sendAppOpenEvent(method: String, adId: String, extras: Map<String, Any?>? = null) {
        val data = mutableMapOf<String, Any?>("id" to adId)
        extras?.let { data.putAll(it) }
        activity?.runOnUiThread { appOpenChannel.invokeMethod(method, data) }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            "hasConsentPurposeOne" -> {
                val sharedPref = PreferenceManager.getDefaultSharedPreferences(context)
                val purposeConsents = sharedPref.getString("IABTCF_PurposeConsents", "") ?: ""

                Log.d("check_purposeConsents", "purposeConsents: $purposeConsents")

                if (purposeConsents.isNotEmpty()) {
                    val hasConsent = purposeConsents[0] == '1'
                    result.success(hasConsent)
                } else {
                    result.success(null)
                }
            }

            "isNetworkActive" -> {
                val isConnected = NetworkUtil().isNetworkActive(context)
                result.success(isConnected)
            }

            "isAdAvailableInter" -> {
                val idAds = call.argument<String>("idAds") ?: ""
                val isAdAvailable = InterManager.isAdAvailable(idAds)
                result.success(isAdAvailable)
            }

            "loadInterAdPreload" -> {
                val idAds = call.argument<String>("idAds") ?: ""
                val numberPreload = call.argument<Int>("numberPreload") ?: 1

                InterManager.loadInterAdPreload(
                    idAds,
                    numberPreload,
                    object : InterCallback {
                        override fun onAdLoaded(adUnit: String?) {
                            sendInterEvent("onAdLoaded", idAds)
                        }

                        override fun onAdFailedToLoad(adUnit: String?, message: String) {
                            sendInterEvent("onAdFailedToLoad", idAds, mapOf("error" to message))
                        }

                        override fun onAdClicked() {

                        }

                        override fun onAdDismissed() {

                        }

                        override fun onAdFailedToShow(message: String) {

                        }

                        override fun onAdImpression() {

                        }

                        override fun onAdShowed() {

                        }

                        override fun onPaidEvent(ad: InterstitialAd, adValue: AdValue) {

                        }
                    }
                )
                result.success(null)
            }

            "showInterAdPreload" -> {
                val idAds = call.argument<String>("idAds") ?: ""
                val act = activity
                if (act == null) {
                    result.error("NO_ACTIVITY", "Activity is null", null)
                    return
                }

                InterManager.showInterAdPreload(
                    act,
                    idAds,
                    object : InterCallback {
                        override fun onAdLoaded(adUnit: String?) {

                        }

                        override fun onAdFailedToLoad(adUnit: String?, message: String) {

                        }

                        override fun onAdClicked() {
                            sendInterEvent("onAdClicked", idAds)
                        }

                        override fun onAdDismissed() {
                            sendInterEvent("onAdDismissed", idAds)
                        }

                        override fun onAdFailedToShow(message: String) {
                            sendInterEvent("onFailedToShow", idAds, mapOf("error" to message))
                        }

                        override fun onAdImpression() {
                            sendInterEvent("onAdImpression", idAds)
                        }

                        override fun onAdShowed() {
                            sendInterEvent("onAdShowed", idAds)
                        }

                        override fun onPaidEvent(ad: InterstitialAd, adValue: AdValue) {
                            val network = ad.responseInfo.loadedAdapterResponseInfo?.adSourceName
                            val valueMicros = adValue.valueMicros
                            val currencyCode = adValue.currencyCode

                            sendInterEvent(
                                "onPaidEvent", idAds, mapOf(
                                    "network" to network,
                                    "valueMicros" to valueMicros,
                                    "currencyCode" to currencyCode
                                )
                            )
                        }

                    }
                )
                result.success(null)
            }

            "destroyInterAdPreload" -> {
                val idAds = call.argument<String>("idAds") ?: ""
                InterManager.destroy(idAds)
                result.success(null)
            }

            "loadAppOpenAdPreload" -> {
                val idAds = call.argument<String>("idAds") ?: ""
                val numberPreload = call.argument<Int>("numberPreload") ?: 1

                AppOpenManager.loadAppOpenAdPreload(
                    idAds,
                    numberPreload,
                    object : AppOpenCallback {
                        override fun onAdLoaded(adUnit: String?) {
                            sendAppOpenEvent("onAdLoaded", idAds)
                        }

                        override fun onAdFailedToLoad(
                            adUnit: String?,
                            message: String
                        ) {
                            sendAppOpenEvent("onAdFailedToLoad", idAds, mapOf("error" to message))
                        }

                        override fun onAdClicked() {

                        }

                        override fun onAdDismissed() {

                        }

                        override fun onAdFailedToShow(message: String) {
                        }

                        override fun onAdImpression() {

                        }

                        override fun onAdShowed() {

                        }

                        override fun onPaidEvent(
                            ad: AppOpenAd,
                            adValue: AdValue
                        ) {

                        }

                    }
                )
                result.success(null)
            }

            "showAppOpenAdPreload" -> {
                val idAds = call.argument<String>("idAds") ?: ""
                val act = activity
                if (act == null) {
                    result.error("NO_ACTIVITY", "Activity is null", null)
                    return
                }

                AppOpenManager.showAppOpenAdPreload(
                    act,
                    idAds,
                    object : AppOpenCallback {
                        override fun onAdLoaded(adUnit: String?) {
                        }

                        override fun onAdFailedToLoad(
                            adUnit: String?,
                            message: String
                        ) {
                        }

                        override fun onAdClicked() {
                            sendAppOpenEvent("onAdClicked", idAds)
                        }

                        override fun onAdDismissed() {
                            sendAppOpenEvent("onAdDismissed", idAds)
                        }

                        override fun onAdFailedToShow(message: String) {
                            sendAppOpenEvent("onFailedToShow", idAds, mapOf("error" to message))
                        }

                        override fun onAdImpression() {
                            sendAppOpenEvent("onAdImpression", idAds)
                        }

                        override fun onAdShowed() {
                            sendAppOpenEvent("onAdShowed", idAds)
                        }

                        override fun onPaidEvent(
                            ad: AppOpenAd,
                            adValue: AdValue
                        ) {
                            val network = ad.responseInfo.loadedAdapterResponseInfo?.adSourceName
                            val valueMicros = adValue.valueMicros
                            val currencyCode = adValue.currencyCode

                            sendAppOpenEvent(
                                "onPaidEvent", idAds, mapOf(
                                    "network" to network,
                                    "valueMicros" to valueMicros,
                                    "currencyCode" to currencyCode
                                )
                            )
                        }

                    }
                )
                result.success(null)
            }

            "isAdAvailableAppOpen" -> {
                val idAds = call.argument<String>("idAds") ?: ""
                val isAdAvailable = AppOpenManager.isAdAvailable(idAds)
                result.success(isAdAvailable)
            }

            "destroyAppOpenAdPreload" -> {
                val idAds = call.argument<String>("idAds") ?: ""
                AppOpenManager.destroy(idAds)
                result.success(null)
            }

            else -> result.notImplemented()
        }

    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        interChannel.setMethodCallHandler(null)
        appOpenChannel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
