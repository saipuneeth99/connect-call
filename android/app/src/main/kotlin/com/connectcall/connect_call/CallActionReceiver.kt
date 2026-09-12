package com.connectcall.connect_call

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.net.HttpURLConnection
import java.net.URL

class CallActionReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_DECLINE_CALL = "com.connectcall.connect_call.ACTION_DECLINE_CALL"
        const val ACTION_ANSWER_CALL = "com.connectcall.connect_call.ACTION_ANSWER_CALL"
        private const val SUPABASE_URL = "https://jfklskprlpwouqzhqzuw.supabase.co"
        private const val SUPABASE_ANON_KEY = "sb_publishable_k2AO6RqzZ3jIm_16PyUnCA_-0kgq-lF"
    }

    override fun onReceive(context: Context, intent: Intent) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(1001)

            when (intent.action) {
                ACTION_DECLINE_CALL -> {
                    val callId = intent.getStringExtra("call_id")
                    MainActivity.onCallDeclinedFromNotification(callId)
                    if (!callId.isNullOrEmpty()) {
                        VoipForegroundService.dismissCallkit(context, callId)
                    }
                    if (!callId.isNullOrEmpty()) {
                        Thread {
                            var conn: HttpURLConnection? = null
                            try {
                                val url = URL("$SUPABASE_URL/rest/v1/calls?id=eq.$callId")
                                conn = (url.openConnection() as HttpURLConnection).apply {
                                    requestMethod = "PATCH"
                                    setRequestProperty("apikey", SUPABASE_ANON_KEY)
                                    setRequestProperty("Authorization", "Bearer $SUPABASE_ANON_KEY")
                                    setRequestProperty("Content-Type", "application/json")
                                    setRequestProperty("Prefer", "return=minimal")
                                    connectTimeout = 3000
                                    readTimeout = 3000
                                    doOutput = true
                                }
                                val nowIso = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                    java.time.Instant.now().toString()
                                } else {
                                    ""
                                }
                                val body = "{\"status\":\"rejected\",\"ended_at\":\"$nowIso\"}"
                                conn.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
                                conn.responseCode
                            } catch (e: Exception) {
                                e.printStackTrace()
                            } finally {
                                try { conn?.disconnect() } catch (_: Exception) {}
                            }
                        }.start()
                    }
                }
                ACTION_ANSWER_CALL -> {
                    val launchIntent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        action = "com.connectcall.ACTION_ANSWER"
                        putExtra("route", "/incoming-call")
                        putExtra("auto_accept", true)
                        val callId = intent.getStringExtra("call_id")
                        if (!callId.isNullOrEmpty()) {
                            putExtra("call_id", callId)
                        }
                    }
                    try {
                        context.startActivity(launchIntent)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
