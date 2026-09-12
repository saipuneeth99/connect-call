package com.connectcall.connect_call

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class CallActionReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_DECLINE_CALL = "com.connectcall.connect_call.ACTION_DECLINE_CALL"
        const val ACTION_ANSWER_CALL = "com.connectcall.connect_call.ACTION_ANSWER_CALL"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(1001)

        when (intent.action) {
            ACTION_DECLINE_CALL -> {
                MainActivity.onCallDeclinedFromNotification()
            }
            ACTION_ANSWER_CALL -> {
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("route", "/incoming-call")
                    putExtra("auto_accept", true)
                }
                context.startActivity(launchIntent)
            }
        }
    }
}
