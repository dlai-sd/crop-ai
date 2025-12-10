package com.dlai.crop

import android.os.Build
import android.os.Bundle
import android.window.SplashScreen.OnExitAnimationListener
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Configure window insets
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
