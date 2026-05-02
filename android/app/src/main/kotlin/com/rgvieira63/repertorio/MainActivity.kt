package com.rgvieira63.repertorio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.seuapp/ad_config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBannerAdUnitId" -> {
                    result.success(BuildConfig.BANNER_AD_UNIT_ID)
                }
                "getRewardedAdUnitId" -> {
                    result.success(BuildConfig.REWARDED_AD_UNIT_ID)
                }
                else -> result.notImplemented()
            }
        }
    }
}