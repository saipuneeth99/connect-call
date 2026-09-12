package com.connectcall.connect_call

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class CallServiceBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }

        val prefs = context.getSharedPreferences(
            VoipForegroundService.PREFS_NAME,
            Context.MODE_PRIVATE,
        )
        val userId = prefs.getString(VoipForegroundService.PREF_USER_ID, null)
        if (!userId.isNullOrEmpty()) {
            VoipForegroundService.startService(context, userId)
        }
    }
}
