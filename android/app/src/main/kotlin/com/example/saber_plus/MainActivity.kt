package com.example.saber_plus

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var privateOfflineVault: PrivateOfflineVault? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        privateOfflineVault = PrivateOfflineVault(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        privateOfflineVault?.close()
        privateOfflineVault = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
