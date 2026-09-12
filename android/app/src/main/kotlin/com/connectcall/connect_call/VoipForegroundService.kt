package com.connectcall.connect_call

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.hiennv.flutter_callkit_incoming.CallkitConstants
import com.hiennv.flutter_callkit_incoming.CallkitIncomingActivity
import com.hiennv.flutter_callkit_incoming.CallkitIncomingBroadcastReceiver
import org.json.JSONArray
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class VoipForegroundService : Service() {
    companion object {
        private const val TAG = "VoipForegroundService"
        const val CHANNEL_ID = "connect_call_bg_service"
        const val NOTIFICATION_ID = 2002
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        const val EXTRA_USER_ID = "EXTRA_USER_ID"
        const val PREFS_NAME = "ConnectCallPrefs"
        const val PREF_USER_ID = "current_user_id"

        private const val SUPABASE_URL = "https://jfklskprlpwouqzhqzuw.supabase.co"
        private const val SUPABASE_ANON_KEY = "sb_publishable_k2AO6RqzZ3jIm_16PyUnCA_-0kgq-lF"

        fun startService(context: Context, userId: String? = null) {
            try {
                if (!userId.isNullOrEmpty()) {
                    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit().putString(PREF_USER_ID, userId).apply()
                }

                val intent = Intent(context, VoipForegroundService::class.java).apply {
                    action = ACTION_START
                    if (!userId.isNullOrEmpty()) {
                        putExtra(EXTRA_USER_ID, userId)
                    }
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error starting VoipForegroundService", e)
            }
        }

        fun stopService(context: Context) {
            try {
                val intent = Intent(context, VoipForegroundService::class.java).apply {
                    action = ACTION_STOP
                }
                context.stopService(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping VoipForegroundService", e)
            }
        }
    }

    private var partialWakeLock: PowerManager.WakeLock? = null
    private var scheduler: ScheduledExecutorService? = null
    private var currentUserId: String? = null
    private var activeRingingCallId: String? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            partialWakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "ConnectCall:VoipKeepAlive"
            ).apply {
                setReferenceCounted(false)
                acquire()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire partial wakelock", e)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopPolling()
            try {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            } catch (e: Exception) {}
            return START_NOT_STICKY
        }

        val intentUserId = intent?.getStringExtra(EXTRA_USER_ID)
        if (!intentUserId.isNullOrEmpty()) {
            currentUserId = intentUserId
        } else {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            currentUserId = prefs.getString(PREF_USER_ID, null)
        }

        val notification = createNotification()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            try {
                startForeground(NOTIFICATION_ID, notification)
            } catch (e2: Exception) {
                Log.e(TAG, "Failed startForeground", e2)
            }
        }

        startPolling()
        return START_STICKY
    }

    private fun startPolling() {
        if (scheduler != null && !scheduler!!.isShutdown) return

        scheduler = Executors.newSingleThreadScheduledExecutor()
        scheduler?.scheduleWithFixedDelay({
            try {
                val uid = currentUserId ?: run {
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.getString(PREF_USER_ID, null)
                }
                if (!uid.isNullOrEmpty()) {
                    currentUserId = uid
                    checkSupabaseForIncomingCalls(uid)
                }
            } catch (e: Throwable) {
                Log.e(TAG, "Error in checkSupabaseForIncomingCalls loop", e)
            }
        }, 500, 1500, TimeUnit.MILLISECONDS)
    }

    private fun stopPolling() {
        try {
            scheduler?.shutdownNow()
            scheduler = null
        } catch (e: Exception) {}
    }

    private fun checkSupabaseForIncomingCalls(userId: String) {
        var connection: HttpURLConnection? = null
        try {
            val queryUrl = "$SUPABASE_URL/rest/v1/calls?receiver_id=eq.$userId&status=eq.ringing&order=started_at.desc&limit=1"
            val url = URL(queryUrl)
            connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                setRequestProperty("apikey", SUPABASE_ANON_KEY)
                setRequestProperty("Authorization", "Bearer $SUPABASE_ANON_KEY")
                setRequestProperty("Accept", "application/json")
                connectTimeout = 3000
                readTimeout = 3000
                useCaches = false
            }

            if (connection.responseCode == 200) {
                val responseText = connection.inputStream.bufferedReader().use { it.readText() }
                val jsonArray = JSONArray(responseText)
                if (jsonArray.length() > 0) {
                    val callObj = jsonArray.getJSONObject(0)
                    val callId = callObj.optString("id")
                    val callerId = callObj.optString("caller_id")
                    val callerName = callObj.optString("caller_name", "Incoming Call")
                    val callType = callObj.optString("type", "audio")
                    val status = callObj.optString("status", "")
                    val startedAtStr = callObj.optString("started_at", "")

                    if (status == "ringing" && callId.isNotEmpty()) {
                        if (callId != activeRingingCallId) {
                            if (isCallRecent(startedAtStr)) {
                                activeRingingCallId = callId
                                triggerIncomingCall(callId, callerId, callerName, callType)
                            }
                        }
                    } else if (activeRingingCallId != null && activeRingingCallId == callId && status != "ringing") {
                        dismissCallkit(callId)
                        activeRingingCallId = null
                    }
                } else if (activeRingingCallId != null) {
                    dismissCallkit(activeRingingCallId!!)
                    activeRingingCallId = null
                }
            }
        } catch (e: Exception) {
            // Socket timeout or temporary connectivity drop is expected during transitions
        } finally {
            try {
                connection?.disconnect()
            } catch (e: Exception) {}
        }
    }

    private fun isCallRecent(startedAtStr: String): Boolean {
        if (startedAtStr.isEmpty()) return true
        return try {
            val timeMs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                java.time.Instant.parse(startedAtStr).toEpochMilli()
            } else {
                val sdf = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US).apply {
                    timeZone = java.util.TimeZone.getTimeZone("UTC")
                }
                sdf.parse(startedAtStr.substring(0, 19))?.time ?: System.currentTimeMillis()
            }
            val age = System.currentTimeMillis() - timeMs
            age in -30000..120000
        } catch (e: Exception) {
            true
        }
    }

    private fun triggerIncomingCall(callId: String, callerId: String, callerName: String, callType: String) {
        try {
            Log.d(TAG, "Triggering native incoming call: $callId from $callerName ($callType)")

            // 1. Wake screen up immediately from lock/sleep
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            val screenWakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                "ConnectCall:IncomingScreenWakeup"
            ).apply {
                setReferenceCounted(false)
                acquire(30000)
            }

            // 2. Build full-screen high-priority notification with system ringtone
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channelId = "connect_call_voip_v3"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .build()

                val channel = NotificationChannel(channelId, "Incoming Phone Calls", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "Incoming voice and video phone calls"
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 1000, 500, 1000, 500, 1000)
                    setSound(ringtoneUri, audioAttributes)
                    lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                    setBypassDnd(true)
                }
                notificationManager.createNotificationChannel(channel)
            }

            val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
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

            val pendingFullScreenIntent = PendingIntent.getActivity(this, 1001, fullScreenIntent, flags)

            val answerIntent = Intent(this, CallActionReceiver::class.java).apply {
                action = CallActionReceiver.ACTION_ANSWER_CALL
            }
            val pendingAnswerIntent = PendingIntent.getBroadcast(this, 1002, answerIntent, flags)

            val declineIntent = Intent(this, CallActionReceiver::class.java).apply {
                action = CallActionReceiver.ACTION_DECLINE_CALL
            }
            val pendingDeclineIntent = PendingIntent.getBroadcast(this, 1003, declineIntent, flags)

            val builder = NotificationCompat.Builder(this, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(callerName)
                .setContentText("Incoming $callType call...")
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_CALL)
                .setAutoCancel(true)
                .setOngoing(true)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setFullScreenIntent(pendingFullScreenIntent, true)
                .setContentIntent(pendingFullScreenIntent)
                .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Decline", pendingDeclineIntent)
                .addAction(android.R.drawable.ic_menu_call, "Answer", pendingAnswerIntent)

            notificationManager.notify(1001, builder.build())

            // 3. Build CallKit parameter bundle
            val bundle = Bundle().apply {
                putString(CallkitConstants.EXTRA_CALLKIT_ID, callId)
                putString(CallkitConstants.EXTRA_CALLKIT_NAME_CALLER, callerName)
                putString(CallkitConstants.EXTRA_CALLKIT_APP_NAME, "ConnectCall")
                putString(CallkitConstants.EXTRA_CALLKIT_HANDLE, callerName)
                putInt(CallkitConstants.EXTRA_CALLKIT_TYPE, if (callType == "video") 1 else 0)
                putLong(CallkitConstants.EXTRA_CALLKIT_DURATION, 45000L)
                putString(CallkitConstants.EXTRA_CALLKIT_TEXT_ACCEPT, "Answer")
                putString(CallkitConstants.EXTRA_CALLKIT_TEXT_DECLINE, "Decline")
                putBoolean(CallkitConstants.EXTRA_CALLKIT_IS_CUSTOM_NOTIFICATION, true)
                putBoolean(CallkitConstants.EXTRA_CALLKIT_IS_SHOW_FULL_LOCKED_SCREEN, true)
                putBoolean(CallkitConstants.EXTRA_CALLKIT_IS_FULL_SCREEN, true)
                putBoolean(CallkitConstants.EXTRA_CALLKIT_IS_IMPORTANT, true)
                putString(CallkitConstants.EXTRA_CALLKIT_ACTION_COLOR, "#10B981")
                putString(CallkitConstants.EXTRA_CALLKIT_BACKGROUND_COLOR, "#0F141C")
                putString(CallkitConstants.EXTRA_CALLKIT_RINGTONE_PATH, "system_ringtone_default")
                val extraMap = HashMap<String, Any>().apply {
                    put("callId", callId)
                    put("callerId", callerId)
                    put("callerName", callerName)
                    put("callType", callType)
                }
                putSerializable(CallkitConstants.EXTRA_CALLKIT_EXTRA, extraMap)
            }

            // 4. Broadcast to CallkitIncomingBroadcastReceiver to trigger sound, vibration, and locked notification
            val incomingBroadcastIntent = CallkitIncomingBroadcastReceiver.getIntentIncoming(this, bundle)
            sendBroadcast(incomingBroadcastIntent)

            // 5. Also launch CallkitIncomingActivity directly to pop up over lockscreen immediately
            try {
                val activityIntent = CallkitIncomingActivity.getIntent(this, bundle).apply {
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                    )
                }
                startActivity(activityIntent)
            } catch (e: Exception) {
                // Background activity launch may be restricted; fullscreen intent notification handles it
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error triggering incoming call", e)
        }
    }

    private fun dismissCallkit(callId: String) {
        try {
            val bundle = Bundle().apply {
                putString(CallkitConstants.EXTRA_CALLKIT_ID, callId)
            }
            val endedIntent = CallkitIncomingBroadcastReceiver.getIntentEnded(this, bundle)
            sendBroadcast(endedIntent)

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(1001)
        } catch (e: Exception) {
            Log.e(TAG, "Error dismissing callkit", e)
        }
    }

    override fun onDestroy() {
        stopPolling()
        try {
            if (partialWakeLock?.isHeld == true) {
                partialWakeLock?.release()
            }
            partialWakeLock = null
        } catch (e: Exception) {}
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Background Connection",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Keeps call connection active for incoming calls"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ConnectCall Active")
            .setContentText("Ready to receive calls")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}
