package com.example.amazic_ads_flutter_example

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.example.amazic_ads_flutter.R
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class NativeAfterInterAd internal constructor(
    private val layoutInflater: LayoutInflater,
    private val nativeMethod: MethodChannel
) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd?,
        customOptions: Map<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(
            R.layout.native_after_inter,
            null
        ) as NativeAdView

        // Set the media view.
        adView.mediaView = adView.findViewById(R.id.ad_media)

        // Set other ad assets.
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_app_icon)

        (adView.headlineView as TextView?)?.text = nativeAd?.headline

        val btnClose: Button = adView.findViewById(R.id.btn_close)

        btnClose.setOnClickListener {
            nativeMethod.invokeMethod("onNativeAfterInterClose",null)
        }

        if (nativeAd?.body == null) {
            adView.bodyView?.visibility = View.INVISIBLE
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView?)?.text = nativeAd.body
        }

        if (nativeAd?.callToAction == null) {
            adView.callToActionView?.visibility = View.INVISIBLE
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button?)?.text = nativeAd?.callToAction
        }

        if (nativeAd?.icon == null) {
            adView.iconView?.visibility = View.GONE
        } else {
            (adView.iconView as ImageView?)?.setImageDrawable(
                nativeAd.icon?.drawable
            )
            adView.iconView?.visibility = View.VISIBLE
        }
        nativeAd?.let { adView.setNativeAd(it) }
        return adView
    }
}