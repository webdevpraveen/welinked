package com.wdp.welinked

import android.content.Context
import android.content.Intent
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.pravera.flutter_foreground_task.service.ForegroundService

/**
 * WorkManager Worker that starts the Flutter foreground service.
 * Used on Android 12+ (API 31+) where calling startForegroundService()
 * directly from a BroadcastReceiver throws ForegroundServiceStartNotAllowedException.
 * WorkManager is exempt from background start restrictions when scheduled
 * from a BOOT_COMPLETED receiver.
 */
class BootStartWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    override fun doWork(): Result {
        return try {
            val serviceIntent = Intent(applicationContext, ForegroundService::class.java)
            applicationContext.startForegroundService(serviceIntent)
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }
}
