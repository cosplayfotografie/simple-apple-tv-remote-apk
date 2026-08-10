package com.example.apple_tv_remote

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import java.util.concurrent.Executors

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.apple_tv_remote/pyatv"
    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var multicastLock: WifiManager.MulticastLock? = null
    private lateinit var nsdManager: NsdManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
        }

        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        multicastLock = wifi.createMulticastLock("apple_tv_remote_multicast_lock")
        multicastLock?.setReferenceCounted(true)
        multicastLock?.acquire()
        
        nsdManager = applicationContext.getSystemService(Context.NSD_SERVICE) as NsdManager
    }

    override fun onDestroy() {
        super.onDestroy()
        multicastLock?.release()
    }

    private fun performNativeScan(onComplete: (String?) -> Unit) {
        val discoveredIps = mutableSetOf<String>()
        val resolveQueue = mutableListOf<NsdServiceInfo>()
        var isResolving = false

        val resolveListener = object : NsdManager.ResolveListener {
            override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                isResolving = false
                processNextResolve(resolveQueue, this, discoveredIps)
            }

            override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                serviceInfo.host?.hostAddress?.let { ip ->
                    discoveredIps.add(ip)
                }
                isResolving = false
                processNextResolve(resolveQueue, this, discoveredIps)
            }
        }

        val discoveryListener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(regType: String) {}
            override fun onServiceFound(service: NsdServiceInfo) {
                if (service.serviceType.contains("_mediaremotetv._tcp") || service.serviceType.contains("_airplay._tcp") || service.serviceType.contains("_appletv-v2._tcp")) {
                    resolveQueue.add(service)
                    if (!isResolving) {
                        isResolving = true
                        processNextResolve(resolveQueue, resolveListener, discoveredIps)
                    }
                }
            }
            override fun onServiceLost(service: NsdServiceInfo) {}
            override fun onDiscoveryStopped(serviceType: String) {}
            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                nsdManager.stopServiceDiscovery(this)
            }
            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
                nsdManager.stopServiceDiscovery(this)
            }
        }

        try {
            nsdManager.discoverServices("_mediaremotetv._tcp.", NsdManager.PROTOCOL_DNS_SD, discoveryListener)
        } catch (e: Exception) {
            // Ignore if already discovering
        }
        
        try {
            nsdManager.discoverServices("_airplay._tcp.", NsdManager.PROTOCOL_DNS_SD, discoveryListener)
        } catch (e: Exception) {
            // Ignore
        }

        // Wait 3.5 seconds to collect IPs
        mainHandler.postDelayed({
            try {
                nsdManager.stopServiceDiscovery(discoveryListener)
            } catch (e: Exception) {}
            
            if (discoveredIps.isEmpty()) {
                onComplete(null)
            } else {
                onComplete(discoveredIps.joinToString(","))
            }
        }, 3500)
    }

    private fun processNextResolve(queue: MutableList<NsdServiceInfo>, listener: NsdManager.ResolveListener, ips: MutableSet<String>) {
        if (queue.isEmpty()) return
        val service = queue.removeAt(0)
        try {
            nsdManager.resolveService(service, listener)
        } catch (e: Exception) {
            // If resolve fails due to busy NsdManager, just skip
            processNextResolve(queue, listener, ips)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val py = try { Python.getInstance() } catch(e: Exception) { null }
            if (py == null) {
                result.error("PYTHON_NOT_STARTED", "Python has not started", null)
                return@setMethodCallHandler
            }
            val module = py.getModule("pyatv_bridge")

            when (call.method) {
                "scan" -> {
                    val manualIp = call.argument<String?>("ip")
                    if (manualIp != null && manualIp.isNotEmpty()) {
                        // Directly scan the provided IP
                        executor.execute {
                            try {
                                val devicesJson = module.callAttr("scan_devices", manualIp).toString()
                                mainHandler.post { result.success(devicesJson) }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("SCAN_ERROR", e.message, null) }
                            }
                        }
                    } else {
                        // Do native NsdManager scan first
                        performNativeScan { ipsCsv ->
                            executor.execute {
                                try {
                                    val args = if (ipsCsv != null) arrayOf(ipsCsv) else arrayOf<String?>(null)
                                    val devicesJson = module.callAttr("scan_devices", *args).toString()
                                    mainHandler.post { result.success(devicesJson) }
                                } catch (e: Exception) {
                                    mainHandler.post { result.error("SCAN_ERROR", e.message, null) }
                                }
                            }
                        }
                    }
                }
                "connect" -> {
                    val identifier = call.argument<String>("identifier")
                    val address = call.argument<String?>("address")
                    val creds = call.argument<String?>("credentials")
                    executor.execute {
                        try {
                            val success = module.callAttr("connect", identifier, address, creds).toBoolean()
                            mainHandler.post { result.success(success) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("CONNECT_ERROR", e.message, null) }
                        }
                    }
                }
                "startPairing" -> {
                    val identifier = call.argument<String>("identifier")
                    val address = call.argument<String?>("address")
                    executor.execute {
                        try {
                            val success = module.callAttr("start_pairing", identifier, address).toBoolean()
                            mainHandler.post { result.success(success) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("PAIRING_ERROR", e.message, null) }
                        }
                    }
                }
                "finishPairing" -> {
                    val pin = call.argument<String>("pin")
                    executor.execute {
                        try {
                            val credentialsJson = module.callAttr("finish_pairing", pin).toString()
                            mainHandler.post { result.success(credentialsJson) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("PAIRING_ERROR", e.message, null) }
                        }
                    }
                }
                "sendCommand" -> {
                    val cmd = call.argument<String>("command")
                    executor.execute {
                        try {
                            val success = module.callAttr("send_command", cmd).toBoolean()
                            mainHandler.post { result.success(success) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("CMD_ERROR", e.message, null) }
                        }
                    }
                }
                "sendText" -> {
                    val text = call.argument<String>("text")
                    executor.execute {
                        try {
                            val success = module.callAttr("send_text", text).toBoolean()
                            mainHandler.post { result.success(success) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("KEYBOARD_ERROR", e.message, null) }
                        }
                    }
                }
                "getApps" -> {
                    executor.execute {
                        try {
                            val appsJson = module.callAttr("get_apps").toString()
                            mainHandler.post { result.success(appsJson) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("APPS_ERROR", e.message, null) }
                        }
                    }
                }
                "launchApp" -> {
                    val identifier = call.argument<String>("identifier")
                    executor.execute {
                        try {
                            val success = module.callAttr("launch_app", identifier).toBoolean()
                            mainHandler.post { result.success(success) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("LAUNCH_ERROR", e.message, null) }
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
