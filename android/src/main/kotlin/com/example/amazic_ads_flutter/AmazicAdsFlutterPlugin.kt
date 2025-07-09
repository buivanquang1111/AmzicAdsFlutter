package com.example.amazic_ads_flutter
import android.content.Context
import android.content.SharedPreferences
import android.preference.PreferenceManager
import android.util.Log
import com.example.amazic_ads_flutter.util.NetworkUtil

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AmazicAdsFlutterPlugin */
class AmazicAdsFlutterPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "amazic_ads_flutter")
    channel.setMethodCallHandler(this)

    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    }else if (call.method == "hasConsentPurposeOne") {
      val sharedPref = PreferenceManager.getDefaultSharedPreferences(context)
      val purposeConsents = sharedPref.getString("IABTCF_PurposeConsents", "") ?: ""

      Log.d("check_purposeConsents", "purposeConsents: $purposeConsents")

      if (purposeConsents.isNotEmpty()) {
        val hasConsent = purposeConsents[0] == '1'
        result.success(hasConsent)
      } else {
        result.success(null)
      }
    } else if(call.method == "isNetworkActive"){
      val isConnected = NetworkUtil().isNetworkActive(context)
      result.success(isConnected)
    }
    else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
