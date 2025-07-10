package com.example.amazic_ads_flutter.ads_banner;

import android.content.Context;

import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.common.MethodChannel;

public class BannerAdsPlatformViewFactory extends PlatformViewFactory {
    private final Context context;
    private final MethodChannel methodChannel;

    public BannerAdsPlatformViewFactory(Context context, MethodChannel methodChannel) {
        super(StandardMessageCodec.INSTANCE);
        this.context = context;
        this.methodChannel = methodChannel;
    }

    @Override
    public PlatformView create(Context context, int id, Object args) {

        return new BannerAdsPlatformView(context, id, args, methodChannel);
    }
}

