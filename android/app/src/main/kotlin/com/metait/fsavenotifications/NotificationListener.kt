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
        @Volatile
        var instance: NotificationListener? = null
            private set
    }

    init {
        instance = this
        isConnected = true
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        isConnected = true
        Log.d(TAG, "NotificationListener onCreate: instance set")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        instance = this
        isConnected = true
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        isConnected = true
        Log.d(TAG, "NotificationListener onListenerConnected: connected successfully")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isConnected = false
        Log.d(TAG, "NotificationListener onListenerDisconnected")
    }

    override fun onDestroy() {
        if (instance == this) {
            instance = null
        }
        isConnected = false
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        instance = this
        isConnected = true
        if (sbn == null) return

        try {
            processAndSaveNotification(sbn, isImport = false)
        } catch (e: Exception) {
            Log.e(TAG, "Error in onNotificationPosted: ${e.message}", e)
        }
    }

    fun processAndSaveNotification(sbn: StatusBarNotification, isImport: Boolean): Long {
        val notification = sbn.notification ?: return -1L
        val extras = notification.extras ?: return -1L

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
            return -1L
        }

        val packageName = sbn.packageName ?: "unknown"

        // Älä tallenna sovelluksen omaa 500-varoitusilmoitusta historiaan
        if (packageName == applicationContext.packageName && sbn.id == 9999) {
            return -1L
        }

        val key = sbn.key ?: "${packageName}_${sbn.id}_${sbn.postTime}"
        val postTime = if (sbn.postTime > 0) sbn.postTime else System.currentTimeMillis()
        val isOngoing = sbn.isOngoing

        val db = NotificationDatabaseHelper.getInstance(applicationContext)

        // Tuonnissa tarkistetaan, onko täsmälleen sama viesti jo aiemmin tallennettu (sekä luetut että lukemattomat)
        if (isImport && db.isNotificationAlreadySaved(key, packageName, title, text, postTime)) {
            Log.d(TAG, "Notification already exists in database, skipping import: $packageName - $title")
            return -1L
        }

        // Resolve human-readable application name
        val appName = try {
            val pm = applicationContext.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }

        val insertedId = db.insertNotification(
            key = key,
            packageName = packageName,
            appName = appName,
            title = title,
            text = text,
            postTime = postTime,
            isOngoing = isOngoing
        )

        Log.d(TAG, "Notification saved (isImport=$isImport): $appName ($packageName): $title | ID: $insertedId")

        if (!isImport) {
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
        }

        return insertedId
    }

    fun importActiveNotifications(): Map<String, Int> {
        var importedCount = 0
        var skippedCount = 0
        var totalCount = 0

        try {
            val activeList = try {
                activeNotifications ?: emptyArray()
            } catch (e: Exception) {
                Log.e(TAG, "Error getting activeNotifications: ${e.message}", e)
                emptyArray()
            }

            totalCount = activeList.size
            Log.d(TAG, "Active notifications found on device: $totalCount")

            for (sbn in activeList) {
                val id = processAndSaveNotification(sbn, isImport = true)
                if (id > 0) {
                    importedCount++
                } else {
                    skippedCount++
                }
            }

            if (importedCount > 0) {
                HistoryAlertManager.checkAndNotify(applicationContext)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error importing active notifications: ${e.message}", e)
        }

        return mapOf(
            "imported" to importedCount,
            "skipped" to skippedCount,
            "total" to totalCount
        )
    }

    fun triggerNotificationIntent(key: String?, packageName: String?): Boolean {
        try {
            val activeList = try {
                activeNotifications ?: emptyArray()
            } catch (e: Exception) {
                Log.e(TAG, "Error accessing activeNotifications: ${e.message}", e)
                emptyArray()
            }

            // 1. Etsitään tarkalla avaimella
            var match: StatusBarNotification? = null
            if (!key.isNullOrBlank()) {
                match = activeList.firstOrNull { it.key == key }
            }

            // 2. Jos ei löydy avaimella, etsitään pakettinimellä
            if (match == null && !packageName.isNullOrBlank()) {
                match = activeList.firstOrNull { it.packageName == packageName }
            }

            if (match?.notification?.contentIntent != null) {
                match.notification.contentIntent.send()
                Log.d(TAG, "Successfully triggered contentIntent for: ${match.packageName} (key: $key)")
                return true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to trigger contentIntent: ${e.message}", e)
        }
        return false
    }
}
