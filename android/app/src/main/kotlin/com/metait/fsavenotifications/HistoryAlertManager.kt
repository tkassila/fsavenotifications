package com.metait.fsavenotifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

object HistoryAlertManager {
    private const val TAG = "HistoryAlertManager"
    private const val CHANNEL_ID = "fsave_history_alert_channel"
    private const val NOTIFICATION_ID = 9999
    private const val PREFS_NAME = "fsave_alert_prefs"
    private const val KEY_LAST_ALERT_TIME = "last_alert_time"
    const val THRESHOLD = 500

    fun checkAndNotify(context: Context, force: Boolean = false) {
        val db = NotificationDatabaseHelper.getInstance(context)
        val readCount = db.getReadCount()
        val totalCount = db.getTotalCount()

        // Katsotaan onko historiaviestejä (luetut tai kokonaismäärä) vähintään 500
        val historyCount = if (readCount >= THRESHOLD) readCount else if (totalCount >= THRESHOLD) totalCount else 0

        if (historyCount < THRESHOLD && !force) {
            return
        }

        val effectiveCount = if (historyCount >= THRESHOLD) historyCount else THRESHOLD

        // Estetään spämmi: ilmoitetaan korkeintaan kerran 15 minuutissa, ellei pakotettu
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lastAlertTime = prefs.getLong(KEY_LAST_ALERT_TIME, 0L)
        val now = System.currentTimeMillis()

        if (!force && (now - lastAlertTime < 15 * 60 * 1000)) {
            Log.d(TAG, "Alert suppressed: notified recently (${now - lastAlertTime} ms ago)")
            return
        }

        sendHistoryAlertNotification(context, effectiveCount)
        prefs.edit().putLong(KEY_LAST_ALERT_TIME, now).apply()
    }

    fun sendHistoryAlertNotification(context: Context, count: Int) {
        try {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val channelName = context.getString(R.string.history_channel_name)
            val channelDesc = context.getString(R.string.history_channel_desc)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    channelName,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = channelDesc
                }
                notificationManager.createNotificationChannel(channel)
            }

            // Linkki ohjelmaan: Avaa MainActivity suoraan Historia-välilehdelle
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("open_tab", "history")
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                NOTIFICATION_ID,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val title = context.getString(R.string.history_alert_title)
            val text = context.getString(R.string.history_alert_text, count)
            val bigText = context.getString(R.string.history_alert_big_text, text)

            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(text)
                .setStyle(
                    NotificationCompat.BigTextStyle()
                        .setBigContentTitle(title)
                        .bigText(bigText)
                )
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .build()

            notificationManager.notify(NOTIFICATION_ID, notification)
            Log.d(TAG, "Sent 500+ history alert notification with $count messages")
        } catch (e: Exception) {
            Log.e(TAG, "Error sending history alert: ${e.message}", e)
        }
    }

    fun cancelAlert(context: Context) {
        try {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(NOTIFICATION_ID)
            Log.d(TAG, "Cancelled history alert notification")
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling alert: ${e.message}", e)
        }
    }
}
