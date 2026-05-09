package com.rgvieira63.repertorio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // Canal definido para bater com o seu código Dart
    private val AD_CHANNEL = "com.seuapp/ad_config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBannerAdUnitId" -> {
                    // Retorna o ID configurado no build.gradle
                    result.success(BuildConfig.BANNER_AD_UNIT_ID)
                }
                "getRewardedAdUnitId" -> {
                    // Retorna o ID configurado no build.gradle
                    result.success(BuildConfig.REWARDED_AD_UNIT_ID)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}