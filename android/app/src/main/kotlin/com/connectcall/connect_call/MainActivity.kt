package com.connectcall.connect_call

import android.app.KeyguardManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.connectcall.connect_call/voip"
        const val PREFS_NAME = "ConnectCallPrefs"
        const val PREF_APP_FOREGROUND = "app_in_foreground"
        private var methodChannel: MethodChannel? = null
        private var activeInstance: MainActivity? = null

        fun onCallDeclinedFromNotification(callId: String? = null) {
            activeInstance?.runOnUiThread {
                try {
                    val args = HashMap<String, Any?>()
                    if (callId != null) args["callId"] = callId
                    methodChannel?.invokeMethod("onCallDeclinedFromNotification", args)
                    activeInstance?.releaseWakeLock()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var proximityWakeLock: PowerManager.WakeLock? = null
    private var pendingRoute: String? = null
    private var pendingAutoAccept: Boolean = false
    private var pendingCallId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        activeInstance = this

        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val savedUserId = prefs.getString("current_user_id", null)
        if (!savedUserId.isNullOrEmpty()) {
            VoipForegroundService.startService(this, savedUserId)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            keyguardManager?.requestDismissKeyguard(this, null)
        }
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )
        handleIntent(intent)
    }

    override fun onStart() {
        super.onStart()
        setAppForeground(true)
    }

    override fun onStop() {
        setAppForeground(false)
        super.onStop()
    }

    private fun setAppForeground(isForeground: Boolean) {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(PREF_APP_FOREGROUND, isForeground)
            .apply()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            keyguardManager?.requestDismissKeyguard(this, null)
        }
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        val autoAccept = intent.getBooleanExtra("auto_accept", false) || intent.action == "com.connectcall.ACTION_ANSWER"
        val route = intent.getStringExtra("route")
        val callId = intent.getStringExtra("call_id")

        if (autoAccept) {
            pendingAutoAccept = true
        }
        if (!route.isNullOrEmpty()) {
            pendingRoute = route
        }
        if (!callId.isNullOrEmpty()) {
            pendingCallId = callId
        }

        dispatchPendingIntent()
    }

    private fun dispatchPendingIntent() {
        val channel = methodChannel ?: return
        runOnUiThread {
            try {
                if (pendingAutoAccept) {
                    pendingAutoAccept = false
                    pendingRoute = null
                    val args = HashMap<String, Any?>().apply {
                        put("callId", pendingCallId)
                    }
                    channel.invokeMethod("onCallAcceptedFromNotification", args)
                } else if (pendingRoute == "/incoming-call") {
                    pendingRoute = null
                    val args = HashMap<String, Any?>().apply {
                        put("callId", pendingCallId)
                    }
                    channel.invokeMethod("navigateToIncomingCall", args)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "setAppInForeground" -> {
                        val isForeground = call.argument<Boolean>("isForeground") ?: true
                        setAppForeground(isForeground)
                        result.success(true)
                    }
                    "wakeUpScreen" -> {
                        wakeUpScreen()
                        result.success(true)
                    }
                    "showIncomingCall" -> {
                        val callerName = call.argument<String>("callerName") ?: "Incoming Call"
                        val callType = call.argument<String>("callType") ?: "audio"
                        val callId = call.argument<String>("callId")
                        showIncomingCallNotification(callerName, callType, callId)
                        wakeUpScreen()
                        result.success(true)
                    }
                    "dismissIncomingCall" -> {
                        dismissIncomingCallNotification()
                        releaseWakeLock()
                        result.success(true)
                    }
                    "enableProximitySensor" -> {
                        enableProximitySensor()
                        result.success(true)
                    }
                    "disableProximitySensor" -> {
                        disableProximitySensor()
                        result.success(true)
                    }
                    "setUserId" -> {
                        val userId = call.argument<String>("userId")
                        val prefs = getSharedPreferences("ConnectCallPrefs", Context.MODE_PRIVATE)
                        prefs.edit().putString("current_user_id", userId).apply()
                        if (!userId.isNullOrEmpty()) {
                            VoipForegroundService.startService(this@MainActivity, userId)
                        }
                        result.success(true)
                    }
                    "startForegroundService" -> {
                        val userId = call.argument<String>("userId")
                        VoipForegroundService.startService(this@MainActivity, userId)
                        result.success(true)
                    }
                    "stopForegroundService" -> {
                        VoipForegroundService.stopService(this@MainActivity)
                        result.success(true)
                    }
                    "requestOverlayPermission" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                if (!Settings.canDrawOverlays(this@MainActivity)) {
                                    val intent = Intent(
                                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                        Uri.parse("package:$packageName")
                                    )
                                    startActivity(intent)
                                }
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            e.printStackTrace()
                            result.success(false)
                        }
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                                if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                        data = Uri.parse("package:$packageName")
                                    }
                                    startActivity(intent)
                                }
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            e.printStackTrace()
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
        dispatchPendingIntent()
    }

    private fun enableProximitySensor() {
        runOnUiThread {
            try {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                @Suppress("DEPRECATION")
                if (powerManager.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) {
                    if (proximityWakeLock == null) {
                        proximityWakeLock = powerManager.newWakeLock(
                            PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                            "ConnectCall:ProximityLock"
                        ).apply {
                            setReferenceCounted(false)
                        }
                    }
                    if (proximityWakeLock?.isHeld == false) {
                        proximityWakeLock?.acquire()
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun disableProximitySensor() {
        runOnUiThread {
            try {
                if (proximityWakeLock?.isHeld == true) {
                    proximityWakeLock?.release()
                }
                proximityWakeLock = null
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun wakeUpScreen() {
        runOnUiThread {
            try {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                releaseWakeLock()
                @Suppress("DEPRECATION")
                wakeLock = powerManager.newWakeLock(
                    PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                    "ConnectCall:VoipWakeLock"
                ).apply {
                    setReferenceCounted(false)
                    acquire(30000)
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                    setShowWhenLocked(true)
                    setTurnScreenOn(true)
                    val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    keyguardManager?.requestDismissKeyguard(this, null)
                }
                @Suppress("DEPRECATION")
                window.addFlags(
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                )

                // Bring MainActivity to the front immediately so incoming caller screen displays
                val launchIntent = Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                    putExtra("route", "/incoming-call")
                    if (!pendingCallId.isNullOrEmpty()) {
                        putExtra("call_id", pendingCallId)
                    }
                }
                startActivity(launchIntent)
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

    private fun showIncomingCallNotification(callerName: String, callType: String, callId: String? = null) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channelId = "connect_call_voip_v5"
            val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .build()

                val channel = NotificationChannel(channelId, "Incoming Phone Calls", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "Incoming voice and video phone calls"
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 1000, 500, 1000, 500, 1000)
                    setSound(ringtoneUri, audioAttributes)
                    lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                    setBypassDnd(true)
                }
                notificationManager.createNotificationChannel(channel)
            }

            // Tap notification intent
            val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                putExtra("route", "/incoming-call")
                if (!callId.isNullOrEmpty()) {
                    putExtra("call_id", callId)
                }
            }

            val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val pendingFullScreenIntent = PendingIntent.getActivity(this, 1001, fullScreenIntent, pendingFlags)

            // Action: Answer (direct activity start so Android never blocks it)
            val answerActivityIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                action = "com.connectcall.ACTION_ANSWER"
                putExtra("route", "/incoming-call")
                putExtra("auto_accept", true)
                if (!callId.isNullOrEmpty()) {
                    putExtra("call_id", callId)
                }
            }
            val pendingAnswerIntent = PendingIntent.getActivity(this, 1002, answerActivityIntent, pendingFlags)

            // Action: Decline
            val declineIntent = Intent(this, CallActionReceiver::class.java).apply {
                action = CallActionReceiver.ACTION_DECLINE_CALL
                if (!callId.isNullOrEmpty()) {
                    putExtra("call_id", callId)
                }
            }
            val pendingDeclineIntent = PendingIntent.getBroadcast(this, 1003, declineIntent, pendingFlags)

            val builder = NotificationCompat.Builder(this, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(callerName)
                .setContentText("Incoming $callType call...")
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_CALL)
                .setAutoCancel(true)
                .setOngoing(true)
                .setSound(ringtoneUri, android.media.AudioManager.STREAM_RING)
                .setVibrate(longArrayOf(0, 1000, 500, 1000, 500, 1000))
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setFullScreenIntent(pendingFullScreenIntent, true)
                .setContentIntent(pendingFullScreenIntent)
                .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Decline", pendingDeclineIntent)
                .addAction(android.R.drawable.ic_menu_call, "Answer", pendingAnswerIntent)

            notificationManager.notify(1001, builder.build())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun dismissIncomingCallNotification() {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(1001)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        try {
            disableProximitySensor()
            releaseWakeLock()
            if (activeInstance == this) {
                activeInstance = null
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        super.onDestroy()
    }
}
