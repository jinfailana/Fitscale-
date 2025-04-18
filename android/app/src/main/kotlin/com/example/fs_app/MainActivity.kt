package com.example.fs_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.os.Bundle
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.StringCodec

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.fitscale.app/settings"
    private val NAVIGATION_CHANNEL = "com.fitscale.app/navigation"
    private lateinit var notificationServiceIntent: Intent
    private lateinit var navigationChannel: BasicMessageChannel<String>
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup navigation channel
        navigationChannel = BasicMessageChannel(flutterEngine.dartExecutor.binaryMessenger, NAVIGATION_CHANNEL, StringCodec.INSTANCE)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openBluetoothSettings") {
                try {
                    // This opens Bluetooth settings directly
                    val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to open Bluetooth settings: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        notificationServiceIntent = Intent(this, NotificationService::class.java)
        startService(notificationServiceIntent)
        
        // Handle navigation from notification
        intent?.let { handleIntent(it) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.hasExtra("start_destination")) {
            when (intent.getStringExtra("start_destination")) {
                "splash" -> {
                    // Send message to Flutter to navigate to splash screen
                    navigationChannel.send("navigate_to_splash")
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Stop notifications when user is actively using the app
        stopService(notificationServiceIntent)
    }

    override fun onPause() {
        super.onPause()
        // Start monitoring for inactivity when app goes to background
        startService(notificationServiceIntent)
    }
} 