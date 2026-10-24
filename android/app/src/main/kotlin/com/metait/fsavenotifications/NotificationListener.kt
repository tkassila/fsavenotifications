package com.metait.fsavenotifications

import android.app.Notification
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        const val ACTION_NEW_NOTIFICATION = "com.metait.fsavenotifications.NEW_NOTIFICATION"
        @Volatile
        var isConnected: Boolean = false
            private set
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isConnected = true
        Log.d(TAG, "NotificationListener connected successfully")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isConnected = false
        Log.d(TAG, "NotificationListener disconnected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        try {
            val notification = sbn.notification ?: return
            val extras = notification.extras ?: return

            // Extract title
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
                ?: extras.getString(Notification.EXTRA_TITLE)
                ?: ""

            // Extract text / body
            val text = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
                ?: extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
                ?: extras.getString(Notification.EXTRA_TEXT)
                ?: ""

            // Skip internal empty notifications
            if (title.isBlank() && text.isBlank()) {
                return
            }

            val packageName = sbn.packageName ?: "unknown"

            // Älä tallenna sovelluksen omaa 500-varoitusilmoitusta historiaan
            if (packageName == applicationContext.packageName && sbn.id == 9999) {
                return
            }

            // Resolve human-readable application name
            val appName = try {
                val pm = applicationContext.packageManager
                val appInfo = pm.getApplicationInfo(packageName, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                packageName
            }

            val key = sbn.key ?: "${packageName}_${sbn.id}_${sbn.postTime}"
            val postTime = if (sbn.postTime > 0) sbn.postTime else System.currentTimeMillis()
            val isOngoing = sbn.isOngoing

            val db = NotificationDatabaseHelper.getInstance(applicationContext)
            val insertedId = db.insertNotification(
                key = key,
                packageName = packageName,
                appName = appName,
                title = title,
                text = text,
                postTime = postTime,
                isOngoing = isOngoing
            )

            Log.d(TAG, "Notification saved: $appName ($packageName): $title | ID: $insertedId")

            // Send local broadcast and notify Flutter if active
            val intent = Intent(ACTION_NEW_NOTIFICATION).apply {
                putExtra("id", insertedId)
                putExtra("packageName", packageName)
                putExtra("appName", appName)
                putExtra("title", title)
                setPackage(applicationContext.packageName)
            }
            sendBroadcast(intent)

            MainActivity.notifyFlutterNewNotification(insertedId, appName, title)

            // Tarkista ylittääkö historiaviestien määrä 500 kappaletta ja ilmoita tarvittaessa
            HistoryAlertManager.checkAndNotify(applicationContext)
        } catch (e: Exception) {
            Log.e(TAG, "Error in onNotificationPosted: ${e.message}", e)
        }
    }
}
