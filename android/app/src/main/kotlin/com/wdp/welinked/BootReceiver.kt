package com.wdp.welinked

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.pravera.flutter_foreground_task.service.ForegroundService

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED || action == "android.intent.action.QUICKBOOT_POWERON") {
            // Auto start the foreground service on boot.
            // The Flutter auth layer handles idle state if user is unauthenticated.
            val serviceIntent = Intent(context, ForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Start service through ForegroundService framework rules on Android 12+
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }
}
