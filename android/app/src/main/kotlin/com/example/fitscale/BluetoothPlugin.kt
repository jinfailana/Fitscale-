package com.example.fitscale

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger

class BluetoothPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var bluetoothManager: BluetoothManager
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngine(binding.binaryMessenger, binding.applicationContext)
    }

    fun onAttachedToEngine(messenger: BinaryMessenger, context: Context) {
        this.context = context
        setupChannels(messenger)
    }

    private fun setupChannels(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, "com.fitscale/bluetooth")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(messenger, "com.fitscale/bluetooth_events")
        bluetoothManager = BluetoothManager(context)
        
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                bluetoothManager.setEventSink(events)
            }

            override fun onCancel(arguments: Any?) {
                bluetoothManager.setEventSink(null)
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "isBluetoothEnabled" -> {
                    result.success(bluetoothManager.isEnabled())
                }
                "enableBluetooth" -> {
                    val enabled = bluetoothManager.enableBluetooth()
                    result.success(enabled)
                }
                "openBluetoothSettings" -> {
                    bluetoothManager.openBluetoothSettings()
                    result.success(true)
                }
                "scanForDevices" -> {
                    bluetoothManager.scanForDevices(result)
                }
                "connectToDevice" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        bluetoothManager.connectToScale(address, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Device address is required", null)
                    }
                }
                "requestWeight" -> {
                    bluetoothManager.requestWeight()
                    result.success(true)
                }
                "disconnectDevice" -> {
                    bluetoothManager.disconnect()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            result.error("BLUETOOTH_ERROR", e.message ?: "Unknown error occurred", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (::bluetoothManager.isInitialized) {
            bluetoothManager.disconnect()
        }
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        // Not used in this implementation
    }

    override fun onDetachedFromActivity() {
        // Not used in this implementation
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        // Not used in this implementation
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // Not used in this implementation
    }
} 