package com.imask.vpn.imask_vpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.imask.vpn/vpn"
    private val VPN_REQUEST_CODE = 2401

    private var pendingResult: MethodChannel.Result? = null
    private var pendingServerName: String = "iMask Server"
    private var pendingServerIp: String = "129.225.114.149"
    private var pendingProtocol: String = "WireGuard"
    private var pendingConfig: String = ""

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "prepareAndConnect" -> {
                        val serverName = call.argument<String>("serverName") ?: "iMask Server"
                        val serverIp = call.argument<String>("serverIp") ?: "129.225.114.149"
                        val protocol = call.argument<String>("protocol") ?: "WireGuard"
                        val config = call.argument<String>("config") ?: ""

                        val prepareIntent = VpnService.prepare(this)
                        if (prepareIntent != null) {
                            // User has not yet granted VPN permission -> show Android system confirmation dialog
                            pendingResult = result
                            pendingServerName = serverName
                            pendingServerIp = serverIp
                            pendingProtocol = protocol
                            pendingConfig = config
                            @Suppress("DEPRECATION")
                            startActivityForResult(prepareIntent, VPN_REQUEST_CODE)
                        } else {
                            // Permission already granted -> start VPN service immediately
                            startIMaskVpnService(serverName, serverIp, protocol, config)
                            result.success(true)
                        }
                    }
                    "disconnect" -> {
                        val stopIntent = Intent(this, IMaskVpnService::class.java).apply {
                            action = IMaskVpnService.ACTION_DISCONNECT
                        }
                        startService(stopIntent)
                        result.success(true)
                    }
                    "isRunning" -> {
                        result.success(IMaskVpnService.isRunning)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startIMaskVpnService(
        serverName: String,
        serverIp: String,
        protocol: String,
        config: String
    ) {
        val serviceIntent = Intent(this, IMaskVpnService::class.java).apply {
            action = IMaskVpnService.ACTION_CONNECT
            putExtra(IMaskVpnService.EXTRA_SERVER_NAME, serverName)
            putExtra(IMaskVpnService.EXTRA_SERVER_IP, serverIp)
            putExtra(IMaskVpnService.EXTRA_PROTOCOL, protocol)
            putExtra(IMaskVpnService.EXTRA_CONFIG, config)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_REQUEST_CODE) {
            val res = pendingResult
            pendingResult = null
            if (resultCode == Activity.RESULT_OK) {
                startIMaskVpnService(
                    pendingServerName,
                    pendingServerIp,
                    pendingProtocol,
                    pendingConfig
                )
                res?.success(true)
            } else {
                // User denied or canceled the VPN confirmation dialog
                res?.success(false)
            }
            return
        }
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
