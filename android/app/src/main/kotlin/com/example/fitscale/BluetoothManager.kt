package com.example.fitscale

import android.Manifest
import android.bluetooth.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.*

class BluetoothManager(private val context: Context) {
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var gatt: BluetoothGatt? = null
    private var classicSocket: BluetoothSocket? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val discoveredDevices = mutableMapOf<String, Map<String, Any>>()
    private var discoveryResult: MethodChannel.Result? = null
    private var isDiscoveryReceiverRegistered = false

    // Standard weight scale service and characteristic UUIDs
    private val WEIGHT_SERVICE_UUID = UUID.fromString("0000181d-0000-1000-8000-00805f9b34fb")
    private val WEIGHT_MEASUREMENT_UUID = UUID.fromString("00002a9d-0000-1000-8000-00805f9b34fb")

    // For classic Bluetooth SPP
    private val SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805f9b34fb")

    // Additional common scale service UUIDs (different manufacturers use different UUIDs)
    private val SCALE_SERVICE_UUIDS = listOf(
        UUID.fromString("0000181d-0000-1000-8000-00805f9b34fb"), // Standard weight scale service
        UUID.fromString("0000ffb0-0000-1000-8000-00805f9b34fb"), // Common custom scale service
        UUID.fromString("0000ffe0-0000-1000-8000-00805f9b34fb")  // Another common custom service
    )

    // Additional common scale characteristic UUIDs
    private val SCALE_CHARACTERISTIC_UUIDS = listOf(
        UUID.fromString("00002a9d-0000-1000-8000-00805f9b34fb"), // Standard weight measurement
        UUID.fromString("0000ffb1-0000-1000-8000-00805f9b34fb"), // Common custom characteristic
        UUID.fromString("0000ffe1-0000-1000-8000-00805f9b34fb")  // Another common custom characteristic
    )

    private val discoveryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    }
                    val rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE).toInt()
                    
                    device?.let {
                        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) {
                            val deviceName = it.name ?: "Unknown Device"
                            discoveredDevices[it.address] = mapOf(
                                "name" to deviceName,
                                "address" to it.address,
                                "rssi" to rssi,
                                "paired" to (it.bondState == BluetoothDevice.BOND_BONDED)
                            )

                            // Send immediate update
                            mainHandler.post {
                                eventSink?.success(mapOf(
                                    "type" to "deviceFound",
                                    "devices" to discoveredDevices.values.toList()
                                ))
                            }
                        }
                    }
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                    unregisterDiscoveryReceiver()
                    mainHandler.post {
                        eventSink?.success(mapOf(
                            "type" to "scanFinished",
                            "devices" to discoveredDevices.values.toList()
                        ))
                    }
                }
                BluetoothAdapter.ACTION_STATE_CHANGED -> {
                    val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
                    when (state) {
                        BluetoothAdapter.STATE_ON -> {
                            eventSink?.success(mapOf(
                                "type" to "stateChange",
                                "state" to "enabled"
                            ))
                        }
                        BluetoothAdapter.STATE_OFF -> {
                            eventSink?.success(mapOf(
                                "type" to "stateChange",
                                "state" to "disabled"
                            ))
                        }
                    }
                }
            }
        }
    }

    init {
        // Register for Bluetooth state changes
        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        context.registerReceiver(discoveryReceiver, filter)
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun isEnabled(): Boolean {
        return bluetoothAdapter?.isEnabled == true
    }

    fun enableBluetooth(): Boolean {
        return if (ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) {
            bluetoothAdapter?.enable() == true
        } else {
            false
        }
    }

    fun scanForDevices(result: MethodChannel.Result) {
        if (!isEnabled()) {
            result.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled", null)
            return
        }

        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "Bluetooth scan permission not granted", null)
            return
        }

        // Cancel any ongoing discovery
        if (bluetoothAdapter?.isDiscovering == true) {
            bluetoothAdapter?.cancelDiscovery()
        }

        discoveredDevices.clear()
        discoveryResult = result

        // Add paired devices first
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) {
            bluetoothAdapter?.bondedDevices?.forEach { device ->
                val deviceName = device.name ?: "Unknown Device"
                // Only include devices that might be scales
                if (deviceName.toLowerCase().contains("scale") || 
                    deviceName.toLowerCase().contains("weight") ||
                    deviceName.toLowerCase().contains("fitscale")) {
                    discoveredDevices[device.address] = mapOf(
                        "name" to deviceName,
                        "address" to device.address,
                        "rssi" to 0,
                        "paired" to true
                    )
                }
            }
        }

        // Register for discoveries if not already registered
        if (!isDiscoveryReceiverRegistered) {
            val filter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_FOUND)
                addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            }
            context.registerReceiver(discoveryReceiver, filter)
            isDiscoveryReceiverRegistered = true
        }

        // Start discovery
        bluetoothAdapter?.startDiscovery()

        // Send initial list of paired devices
        result.success(discoveredDevices.values.toList())

        // Set timeout for discovery
        mainHandler.postDelayed({
            if (bluetoothAdapter?.isDiscovering == true) {
                bluetoothAdapter?.cancelDiscovery()
            }
            unregisterDiscoveryReceiver()
        }, 15000) // 15 seconds timeout
    }

    fun connectToScale(address: String, result: MethodChannel.Result) {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "Bluetooth connect permission not granted", null)
            return
        }

        val device = bluetoothAdapter?.getRemoteDevice(address)
        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Could not find device with address $address", null)
            return
        }

        // Cancel discovery before connecting
        if (bluetoothAdapter?.isDiscovering == true) {
            bluetoothAdapter?.cancelDiscovery()
        }

        try {
            // First try BLE connection
            sendConnectionState(BluetoothConnectionState.CONNECTING)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                gatt = device.connectGatt(context, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
            } else {
                gatt = device.connectGatt(context, false, gattCallback)
            }
            
            // Set a timeout for connection
            mainHandler.postDelayed({
                if (gatt != null) {
                    // If we're still in connecting state after timeout, disconnect
                    gatt?.disconnect()
                    gatt?.close()
                    gatt = null
                    
                    // Try classic Bluetooth as fallback
                    tryClassicConnection(device, result)
                }
            }, 10000) // 10 second timeout
            
            result.success(true)
        } catch (e: Exception) {
            sendConnectionState(BluetoothConnectionState.ERROR)
            result.error("CONNECTION_FAILED", "Failed to connect to scale: ${e.message}", null)
        }
    }

    private fun tryClassicConnection(device: BluetoothDevice, result: MethodChannel.Result) {
        try {
            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                return
            }
            
            // Try to create a classic Bluetooth socket
            classicSocket = device.createRfcommSocketToServiceRecord(SPP_UUID)
            classicSocket?.connect()
            
            // Start a thread to read data
            Thread {
                try {
                    val inputStream = classicSocket?.inputStream
                    val buffer = ByteArray(1024)
                    
                    sendConnectionState(BluetoothConnectionState.CONNECTED)
                    
                    while (true) {
                        val bytes = inputStream?.read(buffer) ?: -1
                        if (bytes > 0) {
                            // Process the received data
                            processScaleData(buffer, bytes)
                        }
                    }
                } catch (e: IOException) {
                    sendConnectionState(BluetoothConnectionState.ERROR)
                    disconnect()
                }
            }.start()
            
        } catch (e: Exception) {
            sendConnectionState(BluetoothConnectionState.ERROR)
            disconnect()
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    mainHandler.post {
                        this@BluetoothManager.gatt = gatt
                        gatt.discoverServices()
                        sendConnectionState(BluetoothConnectionState.CONNECTED)
                    }
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    mainHandler.post {
                        sendConnectionState(BluetoothConnectionState.DISCONNECTED)
                        gatt.close()
                        this@BluetoothManager.gatt = null
                    }
                }
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                // Try to find any of the scale service UUIDs
                var foundService = false
                
                for (serviceUuid in SCALE_SERVICE_UUIDS) {
                    val service = gatt.getService(serviceUuid)
                    if (service != null) {
                        // Try to find any of the scale characteristic UUIDs
                        for (charUuid in SCALE_CHARACTERISTIC_UUIDS) {
                            val characteristic = service.getCharacteristic(charUuid)
                            if (characteristic != null) {
                                if (ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) {
                                    gatt.setCharacteristicNotification(characteristic, true)
                                    foundService = true
                                    
                                    // Request a weight reading
                                    mainHandler.postDelayed({
                                        requestWeight()
                                    }, 1000)
                                }
                                break
                            }
                        }
                        
                        if (foundService) break
                    }
                }
                
                // If no known service was found, try to enable notifications on all readable characteristics
                if (!foundService) {
                    for (service in gatt.services) {
                        for (characteristic in service.characteristics) {
                            if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0 ||
                                characteristic.properties and BluetoothGattCharacteristic.PROPERTY_INDICATE != 0) {
                                if (ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) {
                                    gatt.setCharacteristicNotification(characteristic, true)
                                }
                            }
                        }
                    }
                    
                    // Request a weight reading
                    mainHandler.postDelayed({
                        requestWeight()
                    }, 1000)
                }
            }
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            // Process the characteristic data
            val data = characteristic.value
            if (data != null && data.isNotEmpty()) {
                processScaleData(data, data.size)
            }
        }
    }

    fun requestWeight() {
        if (gatt == null) return
        
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            return
        }
        
        // Try to find a writable characteristic to request weight
        for (serviceUuid in SCALE_SERVICE_UUIDS) {
            val service = gatt?.getService(serviceUuid) ?: continue
            
            for (charUuid in SCALE_CHARACTERISTIC_UUIDS) {
                val characteristic = service.getCharacteristic(charUuid) ?: continue
                
                if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_WRITE != 0 ||
                    characteristic.properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0) {
                    
                    // Send a command to request weight (this will vary by scale manufacturer)
                    characteristic.setValue(byteArrayOf(0x01, 0x02, 0x03)) // Example command
                    gatt?.writeCharacteristic(characteristic)
                    return
                }
            }
        }
    }

    private fun processScaleData(data: ByteArray, length: Int) {
        // This is a simplified example - actual implementation will depend on your scale's protocol
        try {
            // Simple example: assume the first byte is the weight in kg
            val weight = data[0].toDouble()
            
            // Send the weight data to Flutter
            mainHandler.post {
                eventSink?.success(mapOf(
                    "type" to "scaleData",
                    "weight" to weight,
                    "unit" to "kg",
                    "timestamp" to System.currentTimeMillis()
                ))
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun sendConnectionState(state: BluetoothConnectionState) {
        mainHandler.post {
            eventSink?.success(mapOf(
                "type" to "connectionState",
                "value" to state.ordinal
            ))
        }
    }

    fun disconnect() {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) {
            if (bluetoothAdapter?.isDiscovering == true) {
                bluetoothAdapter?.cancelDiscovery()
            }
        }
        
        // Close GATT connection
        gatt?.disconnect()
        gatt?.close()
        gatt = null
        
        // Close classic socket
        try {
            classicSocket?.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        classicSocket = null
        
        unregisterDiscoveryReceiver()
        sendConnectionState(BluetoothConnectionState.DISCONNECTED)
    }

    private fun unregisterDiscoveryReceiver() {
        if (isDiscoveryReceiverRegistered) {
            try {
                context.unregisterReceiver(discoveryReceiver)
                isDiscoveryReceiverRegistered = false
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun openBluetoothSettings() {
        val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    enum class BluetoothConnectionState {
        DISCONNECTED,
        CONNECTING,
        CONNECTED,
        ERROR
    }
} 