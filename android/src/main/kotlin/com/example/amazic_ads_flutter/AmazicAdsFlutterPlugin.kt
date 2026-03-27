package com.example.amazic_ads_flutter

import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import android.preference.PreferenceManager
import android.util.Log
import com.example.amazic_ads_flutter.util.NetworkUtil

import com.example.amazic_ads_flutter.ads_banner.BannerAdsPlatformViewFactory;
import com.example.amazic_ads_flutter.callback.InterCallback
import com.example.amazic_ads_flutter.inter_ads.InterManager
import com.google.android.gms.ads.AdValue
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

            "loadInterAdPreload" -> {
                val idAds = call.argument<String>("idAds") ?: ""
                val numberPreload = call.argument<Int>("numberPreload") ?: 1

                InterManager.loadInterAdPreload(
                    idAds,
                    numberPreload,
                    object : InterCallback {
                        override fun onAdLoaded(adUnit: String?) {
                            activity?.runOnUiThread { channel.invokeMethod("onAdLoaded", adUnit) }
                        }

                        override fun onAdFailedToLoad(adUnit: String?, message: String) {
                            activity?.runOnUiThread {
                                channel.invokeMethod(
                                    "onAdFailedToLoad",
                                    mapOf("id" to adUnit, "error" to message)
                                )
                            }
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
                            act.runOnUiThread { channel.invokeMethod("onAdClicked", idAds) }
                        }

                        override fun onAdDismissed() {
                            act.runOnUiThread { channel.invokeMethod("onDismissed", idAds) }
                        }

                        override fun onAdFailedToShow(message: String) {
                            act.runOnUiThread {
                                channel.invokeMethod(
                                    "onFailedToShow",
                                    mapOf("id" to idAds, "error" to message)
                                )
                            }
                        }

                        override fun onAdImpression() {
                            act.runOnUiThread { channel.invokeMethod("onAdImpression", idAds) }
                        }

                        override fun onAdShowed() {
                            act.runOnUiThread { channel.invokeMethod("onAdShowed", idAds) }
                        }

                        override fun onPaidEvent(ad: InterstitialAd, adValue: AdValue) {
                            val network = ad.responseInfo.loadedAdapterResponseInfo?.adSourceName
                            val valueMicros = adValue.valueMicros
                            val currencyCode = adValue.currencyCode

                            act.runOnUiThread {
                                channel.invokeMethod(
                                    "onPaidEvent",
                                    mapOf(
                                        "network" to network,
                                        "valueMicros" to valueMicros,
                                        "currencyCode" to currencyCode
                                    )
                                )
                            }
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


            else -> result.notImplemented()
        }

    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
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
