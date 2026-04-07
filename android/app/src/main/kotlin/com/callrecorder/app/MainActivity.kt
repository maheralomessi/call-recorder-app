package com.callrecorder.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channel = "com.callrecorder/service"
    private var methodChannel: MethodChannel? = null

    private val newRecordingReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            val path = intent?.getStringExtra("file_path") ?: return
            val duration = intent.getLongExtra("duration", 0)
            val phoneNumber = intent.getStringExtra("phone_number") ?: "Unknown"
            val callType = intent.getStringExtra("call_type") ?: "unknown"
            val file = File(path)
            val size = if (file.exists()) file.length() else 0L

            runOnUiThread {
                methodChannel?.invokeMethod("onNewRecording", mapOf(
                    "filePath" to path,
                    "duration" to duration,
                    "phoneNumber" to phoneNumber,
                    "callType" to callType,
                    "fileSize" to size,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setAutoRecord" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    getSharedPreferences("call_recorder", Context.MODE_PRIVATE)
                        .edit().putBoolean("auto_record", enabled).apply()
                    result.success(null)
                }
                "getRecordings" -> {
                    val dir = File(getExternalFilesDir(null), "CallRecordings")
                    val files = if (dir.exists()) dir.listFiles()?.map { it.absolutePath } ?: emptyList()
                               else emptyList<String>()
                    result.success(files)
                }
                else -> result.notImplemented()
            }
        }

        val filter = IntentFilter("com.callrecorder.NEW_RECORDING")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(newRecordingReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(newRecordingReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try { unregisterReceiver(newRecordingReceiver) } catch (_: Exception) {}
    }
}
