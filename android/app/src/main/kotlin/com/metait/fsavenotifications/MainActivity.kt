package com.metait.fsavenotifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.text.TextUtils
import androidx.annotation.NonNull
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.metait.fsavenotifications/channel"
        private const val PERMISSION_REQUEST_POST_NOTIFICATIONS = 101
        private var methodChannel: MethodChannel? = null

        fun notifyFlutterNewNotification(id: Long, appName: String, title: String) {
            Handler(Looper.getMainLooper()).post {
                methodChannel?.invokeMethod(
                    "onNewNotification",
                    mapOf("id" to id, "appName" to appName, "title" to title)
                )
            }
        }
    }

    private var initialTab: String? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Capture initial tab from launch intent (e.g. from 500+ history alert notification)
        if (intent?.hasExtra("open_tab") == true) {
            initialTab = intent.getStringExtra("open_tab")
        }

        // Pyydetään ilmoitusoikeus automaattisesti Android 13+ (API 33+) -laitteilla
        requestPostNotificationsIfRequired()

        // Varmista että ilmoituspalvelu on sidottu heti käynnistyksessä jos lupa on myönnetty
        if (isNotificationAccessGranted() && (NotificationListener.instance == null || !NotificationListener.isConnected)) {
            rebindNotificationListener()
        }

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            val db = NotificationDatabaseHelper.getInstance(applicationContext)

            when (call.method) {
                "getUnreadNotifications" -> {
                    try {
                        val list = db.getUnreadNotifications()
                        result.success(list)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }

                "getAllNotifications" -> {
                    try {
                        val list = db.getAllNotifications()
                        result.success(list)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }

                "markAsRead" -> {
                    try {
                        val id = (call.argument<Number>("id"))?.toLong() ?: 0L
                        val success = db.markAsRead(id)
                        if (success) {
                            HistoryAlertManager.checkAndNotify(applicationContext)
                        }
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }

                "markAllAsRead" -> {
                    try {
                        val count = db.markAllAsRead()
                        if (count > 0) {
                            HistoryAlertManager.checkAndNotify(applicationContext)
                        }
                        result.success(count)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }

                "deleteNotification" -> {
                    try {
                        val id = (call.argument<Number>("id"))?.toLong() ?: 0L
                        val success = db.deleteNotification(id)
                        HistoryAlertManager.checkAndNotify(applicationContext)
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }

                "clearAll" -> {
                    try {
                        val count = db.clearAll()
                        HistoryAlertManager.cancelAlert(applicationContext)
                        result.success(count)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }

                "clearRead" -> {
                    try {
                        val count = db.clearRead()
                        HistoryAlertManager.cancelAlert(applicationContext)
                        result.success(count)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }

                "getStats" -> {
                    try {
                        val stats = db.getStats()
                        result.success(stats)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }

                "isNotificationAccessGranted" -> {
                    result.success(isNotificationAccessGranted())
                }

                "openNotificationAccessSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }

                "openAppSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", packageName, null)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }

                "isIgnoringBatteryOptimizations" -> {
                    try {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        // Fallback järjestelmän yleiseen akkuasetuslistaan
                        try {
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (ex: Exception) {
                            result.error("BATTERY_ERROR", ex.message, null)
                        }
                    }
                }

                "requestNotificationPermission" -> {
                    requestPostNotificationsIfRequired()
                    result.success(true)
                }

                "isListenerConnected" -> {
                    result.success(NotificationListener.isConnected)
                }

                "sendTestNotification" -> {
                    try {
                        val title = call.argument<String>("title") ?: "Testi-ilmoitus"
                        val message = call.argument<String>("message") ?: "Tämä on tallennettu testiviesti."
                        sendTestNotification(title, message)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", e.message, null)
                    }
                }

                "getInitialTab" -> {
                    val tab = initialTab
                    initialTab = null
                    result.success(tab)
                }

                "triggerHistoryAlert" -> {
                    try {
                        HistoryAlertManager.checkAndNotify(applicationContext, force = true)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ALERT_ERROR", e.message, null)
                    }
                }

                "insertBatchTestMessages" -> {
                    try {
                        val count = (call.argument<Number>("count"))?.toInt() ?: 500
                        val markAsRead = call.argument<Boolean>("markAsRead") ?: true
                        val inserted = db.insertBatchTestMessages(count, markAsRead)
                        HistoryAlertManager.checkAndNotify(applicationContext, force = true)
                        result.success(inserted)
                    } catch (e: Exception) {
                        result.error("BATCH_ERROR", e.message, null)
                    }
                }

                "importActiveNotifications" -> {
                    val hasPerm = isNotificationAccessGranted()
                    if (!hasPerm) {
                        result.success(
                            mapOf(
                                "imported" to 0,
                                "skipped" to 0,
                                "total" to 0,
                                "permissionGranted" to false,
                                "connected" to false
                            )
                        )
                        return@setMethodCallHandler
                    }

                    // Suoritetaan taustasäikeessä, jotta mahdollinen palvelun sidonta (rebind) ehtii tapahtua ilman UI-jumiutumista
                    Thread {
                        var listener = NotificationListener.instance

                        if (listener == null || !NotificationListener.isConnected) {
                            android.util.Log.d("MainActivity", "NotificationListener not connected, executing rebind...")
                            rebindNotificationListener()

                            // Odotetaan enintään 1.5 sekuntia palvelun sitoutumista
                            for (i in 1..15) {
                                try {
                                    Thread.sleep(100)
                                } catch (_: InterruptedException) {}
                                listener = NotificationListener.instance
                                if (listener != null) {
                                    android.util.Log.d("MainActivity", "NotificationListener connected after ${i * 100} ms")
                                    break
                                }
                            }
                        }

                        Handler(Looper.getMainLooper()).post {
                            val currentListener = NotificationListener.instance ?: listener
                            if (currentListener == null) {
                                android.util.Log.w("MainActivity", "NotificationListener still not connected after rebind attempt")
                                result.success(
                                    mapOf(
                                        "imported" to 0,
                                        "skipped" to 0,
                                        "total" to 0,
                                        "permissionGranted" to true,
                                        "connected" to false
                                    )
                                )
                            } else {
                                try {
                                    val stats = currentListener.importActiveNotifications()
                                    result.success(
                                        mapOf(
                                            "imported" to (stats["imported"] ?: 0),
                                            "skipped" to (stats["skipped"] ?: 0),
                                            "total" to (stats["total"] ?: 0),
                                            "permissionGranted" to true,
                                            "connected" to true
                                        )
                                    )
                                } catch (e: Exception) {
                                    result.error("IMPORT_ERROR", e.message, null)
                                }
                            }
                        }
                    }.start()
                }

                "openNotification" -> {
                    val key = call.argument<String>("key")
                    val packageName = call.argument<String>("packageName")
                    var opened = false

                    // 1. Kokeillaan ensin laukaista alkuperäisen ilmoituksen oma Intent, jos se on yhä aktiivinen laitteessa
                    val listener = NotificationListener.instance
                    if (listener != null) {
                        opened = listener.triggerNotificationIntent(key, packageName)
                    }

                    // 2. Jos ei ollut aktiivinen tai PendingIntent epäonnistui, avataan sovelluksen pääaktiviteetti
                    if (!opened && !packageName.isNullOrBlank()) {
                        try {
                            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                            if (launchIntent != null) {
                                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(launchIntent)
                                opened = true
                            } else {
                                android.util.Log.w("MainActivity", "Launch intent not found for package: $packageName")
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("MainActivity", "Failed to launch package $packageName: ${e.message}", e)
                        }
                    }

                    result.success(opened)
                }

                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (!url.isNullOrBlank()) {
                        try {
                            var uriString = url.trim()
                            if (!uriString.startsWith("http://", ignoreCase = true) &&
                                !uriString.startsWith("https://", ignoreCase = true) &&
                                !uriString.startsWith("tel:", ignoreCase = true) &&
                                !uriString.startsWith("mailto:", ignoreCase = true)
                            ) {
                                uriString = "https://$uriString"
                            }
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uriString)).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            android.util.Log.e("MainActivity", "Failed to open URL $url: ${e.message}", e)
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun rebindNotificationListener() {
        try {
            val componentName = ComponentName(this, NotificationListener::class.java)
            val pm = packageManager

            pm.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
            pm.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                android.service.notification.NotificationListenerService.requestRebind(componentName)
            }
            android.util.Log.d("MainActivity", "rebindNotificationListener executed")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to rebind NotificationListener: ${e.message}")
        }
    }

    private fun requestPostNotificationsIfRequired() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    android.Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                requestPermissions(
                    arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                    PERMISSION_REQUEST_POST_NOTIFICATIONS
                )
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val openTab = intent?.getStringExtra("open_tab")
        if (openTab != null) {
            methodChannel?.invokeMethod("openTab", mapOf("tab" to openTab))
        }
    }

    override fun onDestroy() {
        methodChannel = null
        super.onDestroy()
    }

    private fun isNotificationAccessGranted(): Boolean {
        return try {
            val listeners = NotificationManagerCompat.getEnabledListenerPackages(this)
            if (listeners.contains(packageName)) {
                return true
            }
            // Fallback via Settings.Secure
            val flat = Settings.Secure.getString(
                contentResolver,
                "enabled_notification_listeners"
            )
            if (!TextUtils.isEmpty(flat)) {
                val names = flat.split(":".toRegex()).toTypedArray()
                for (name in names) {
                    val cn = ComponentName.unflattenFromString(name)
                    if (cn != null && TextUtils.equals(packageName, cn.packageName)) {
                        return true
                    }
                }
            }
            false
        } catch (e: Exception) {
            false
        }
    }

    private fun sendTestNotification(title: String, message: String) {
        val channelId = "fsave_test_channel"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                getString(R.string.test_channel_name),
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = getString(R.string.test_channel_desc)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify((System.currentTimeMillis() % 100000).toInt(), notification)
    }
}
