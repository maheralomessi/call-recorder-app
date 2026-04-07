package com.callrecorder.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat

class CallReceiver : BroadcastReceiver() {
    private var lastState = TelephonyManager.EXTRA_STATE_IDLE
    private var lastNumber = ""

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences("call_recorder", Context.MODE_PRIVATE)
        val autoRecord = prefs.getBoolean("auto_record", true)
        if (!autoRecord) return

        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER) ?: ""

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                lastNumber = incomingNumber
            }
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                if (lastState == TelephonyManager.EXTRA_STATE_RINGING) {
                    startRecording(context, lastNumber, "incoming")
                } else if (lastState == TelephonyManager.EXTRA_STATE_IDLE) {
                    startRecording(context, "Unknown", "outgoing")
                }
            }
            TelephonyManager.EXTRA_STATE_IDLE -> {
                if (lastState != TelephonyManager.EXTRA_STATE_IDLE) {
                    stopRecording(context)
                }
                lastNumber = ""
            }
        }
        lastState = state
    }

    private fun startRecording(context: Context, number: String, callType: String) {
        val intent = Intent(context, RecordingService::class.java).apply {
            action = RecordingService.ACTION_START
            putExtra("phone_number", number)
            putExtra("call_type", callType)
        }
        ContextCompat.startForegroundService(context, intent)
    }

    private fun stopRecording(context: Context) {
        val intent = Intent(context, RecordingService::class.java).apply {
            action = RecordingService.ACTION_STOP
        }
        context.startService(intent)
    }
}
