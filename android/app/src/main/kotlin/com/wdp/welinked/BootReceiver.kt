package com.wdp.welinked

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.pravera.flutter_foreground_task.service.ForegroundService

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED || action == "android.intent.action.QUICKBOOT_POWERON") {
            // Auto start the foreground service on boot.
            // The Flutter auth layer handles idle state if user is unauthenticated.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Android 12+: Use WorkManager to avoid ForegroundServiceStartNotAllowedException.
                // WorkManager is exempt from background start restrictions when scheduled
                // from a BOOT_COMPLETED receiver.
                val workRequest = OneTimeWorkRequestBuilder<BootStartWorker>().build()
                WorkManager.getInstance(context).enqueue(workRequest)
            } else {
                // Android < 12: Direct service start is safe.
                val serviceIntent = Intent(context, ForegroundService::class.java)
                context.startService(serviceIntent)
            }
        }
    }
}
