package com.callrecorder.app

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.MediaRecorder
import android.os.*
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class RecordingService : Service() {

    companion object {
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        const val CHANNEL_ID = "CallRecorderChannel"
        const val NOTIFICATION_ID = 1001
        private const val TAG = "RecordingService"
    }

    private var mediaRecorder: MediaRecorder? = null
    private var currentFilePath: String? = null
    private var startTime: Long = 0
    private var currentPhoneNumber: String = "Unknown"
    private var currentCallType: String = "unknown"

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                currentPhoneNumber = intent.getStringExtra("phone_number") ?: "Unknown"
                currentCallType = intent.getStringExtra("call_type") ?: "unknown"
                startRecording()
            }
            ACTION_STOP -> stopRecording()
        }
        return START_NOT_STICKY
    }

    private fun startRecording() {
        val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val sanitized = currentPhoneNumber.replace(Regex("[^0-9+]"), "")
        val fileName = "call_${sanitized}_${timestamp}.m4a"
        val dir = File(getExternalFilesDir(null), "CallRecordings").also { if (!it.exists()) it.mkdirs() }
        currentFilePath = "${dir.absolutePath}/$fileName"
        startTime = System.currentTimeMillis()

        val prefs = getSharedPreferences("call_recorder", Context.MODE_PRIVATE)
        val quality = prefs.getString("quality", "high") ?: "high"
        val bitrate = when (quality) { "low" -> 64000; "medium" -> 96000; else -> 128000 }

        try {
            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(this)
                            else @Suppress("DEPRECATION") MediaRecorder()

            mediaRecorder?.apply {
                try { setAudioSource(MediaRecorder.AudioSource.VOICE_COMMUNICATION) }
                catch (e: Exception) { setAudioSource(MediaRecorder.AudioSource.MIC) }
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioEncodingBitRate(bitrate)
                setAudioSamplingRate(44100)
                setOutputFile(currentFilePath)
                prepare()
                start()
            }

            startForeground(NOTIFICATION_ID, buildNotification("جاري تسجيل المكالمة مع $currentPhoneNumber"))
            Log.d(TAG, "Recording started: $currentFilePath")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start recording: ${e.message}", e)
            stopSelf()
        }
    }

    private fun stopRecording() {
        val duration = (System.currentTimeMillis() - startTime) / 1000
        try {
            mediaRecorder?.apply { stop(); release() }
            mediaRecorder = null

            val file = currentFilePath?.let { File(it) }
            val fileSize = file?.length() ?: 0L

            sendBroadcast(Intent("com.callrecorder.NEW_RECORDING").apply {
                putExtra("file_path", currentFilePath)
                putExtra("duration", duration)
                putExtra("phone_number", currentPhoneNumber)
                putExtra("call_type", currentCallType)
                putExtra("file_size", fileSize)
            })
            Log.d(TAG, "Recording saved: $currentFilePath (${duration}s)")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping recording", e)
            currentFilePath?.let { File(it).takeIf { f -> f.exists() }?.delete() }
        } finally {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) stopForeground(STOP_FOREGROUND_REMOVE)
            else @Suppress("DEPRECATION") stopForeground(true)
            stopSelf()
        }
    }

    private fun buildNotification(text: String): Notification {
        val pi = PendingIntent.getActivity(this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE)
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("🎙️ مسجّل المكالمات")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(pi)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(CHANNEL_ID, "تسجيل المكالمات", NotificationManager.IMPORTANCE_LOW)
                .apply { description = "يعمل أثناء تسجيل المكالمات" }
            getSystemService(NotificationManager::class.java).createNotificationChannel(ch)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
