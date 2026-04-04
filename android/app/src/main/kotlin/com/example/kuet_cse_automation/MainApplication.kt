package com.example.kuet_cse_automation

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

/**
 * Custom Application class that registers all notification channels at process startup,
 * before any Dart/Flutter code runs.
 *
 * This is required because flutter_background_service calls startForeground() on the
 * Android-side *before* the Dart isolate has had a chance to create channels via
 * FlutterLocalNotificationsPlugin.  On Android 8+ (and especially Android 14+) calling
 * startForeground() with a non-existent channel throws
 * CannotPostForegroundServiceNotificationException and kills the process.
 */
class MainApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannels()
        }
    }

    private fun createNotificationChannels() {
        val manager = getSystemService(NotificationManager::class.java)

        // ── Background sync foreground-service channel ─────────────────────
        // ID must match notificationChannelId in AndroidConfiguration (Dart side).
        val bgSync = NotificationChannel(
            "kuet_bg_sync",
            "Background Sync",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Silent background notification sync service"
            enableVibration(false)
            setSound(null, null)
            setShowBadge(false)
        }

        // ── Main alerts channel ─────────────────────────────────────────────
        val alerts = NotificationChannel(
            "kuet_notifications",
            "KUET Notifications",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Real-time department updates and alerts"
            enableVibration(true)
            setShowBadge(true)
        }

        // ── Reminders channel ───────────────────────────────────────────────
        val reminders = NotificationChannel(
            "kuet_reminders",
            "Class & Exam Reminders",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Scheduled class and exam reminders"
            enableVibration(true)
            setShowBadge(true)
        }

        manager.createNotificationChannels(
            listOf(bgSync, alerts, reminders)
        )
    }
}
