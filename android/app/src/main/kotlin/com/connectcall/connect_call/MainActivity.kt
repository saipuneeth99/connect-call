package com.connectcall.connect_call

import android.app.KeyguardManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.connectcall.connect_call/voip"
    private var wakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "wakeUpScreen" -> {
                    wakeUpScreen()
                    result.success(true)
                }
                "showIncomingCall" -> {
                    val callerName = call.argument<String>("callerName") ?: "Incoming Call"
                    val callType = call.argument<String>("callType") ?: "audio"
                    showIncomingCallNotification(callerName, callType)
                    wakeUpScreen()
                    result.success(true)
                }
                "dismissIncomingCall" -> {
                    dismissIncomingCallNotification()
                    releaseWakeLock()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun wakeUpScreen() {
        runOnUiThread {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                    setShowWhenLocked(true)
                    setTurnScreenOn(true)
                    val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    keyguardManager?.requestDismissKeyguard(this, null)
                } else {
                    @Suppress("DEPRECATION")
                    window.addFlags(
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    )
                }

                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                releaseWakeLock()
                @Suppress("DEPRECATION")
                wakeLock = powerManager.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                    "ConnectCall:VoipWakeLock"
                ).apply {
                    setReferenceCounted(false)
                    acquire(25000)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
            wakeLock = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showIncomingCallNotification(callerName: String, callType: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "connect_call_voip_v2"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .build()

            val channel = NotificationChannel(channelId, "Incoming Calls", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Incoming voice and video calls"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 1000, 500, 1000, 500, 1000)
                setSound(ringtoneUri, audioAttributes)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            putExtra("route", "/incoming-call")
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getActivity(this, 1001, intent, flags)

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(callerName)
            .setContentText("Incoming $callType call...")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setAutoCancel(true)
            .setOngoing(true)
            .setFullScreenIntent(pendingIntent, true)
            .setContentIntent(pendingIntent)

        notificationManager.notify(1001, builder.build())
    }

    private fun dismissIncomingCallNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(1001)
    }

    override fun onDestroy() {
        releaseWakeLock()
        super.onDestroy()
    }
}
