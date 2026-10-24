package com.metait.fsavenotifications

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class NotificationDatabaseHelper private constructor(context: Context) :
    SQLiteOpenHelper(context.applicationContext, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "notifications.db"
        private const val DATABASE_VERSION = 1

        const val TABLE_NAME = "notifications"
        const val COLUMN_ID = "id"
        const val COLUMN_KEY = "notification_key"
        const val COLUMN_PACKAGE_NAME = "package_name"
        const val COLUMN_APP_NAME = "app_name"
        const val COLUMN_TITLE = "title"
        const val COLUMN_TEXT = "text"
        const val COLUMN_POST_TIME = "post_time"
        const val COLUMN_IS_READ = "is_read"
        const val COLUMN_READ_AT = "read_at"
        const val COLUMN_IS_ONGOING = "is_ongoing"

        @Volatile
        private var instance: NotificationDatabaseHelper? = null

        fun getInstance(context: Context): NotificationDatabaseHelper {
            return instance ?: synchronized(this) {
                instance ?: NotificationDatabaseHelper(context).also { instance = it }
            }
        }
    }

    override fun onCreate(db: SQLiteDatabase) {
        val createTableQuery = """
            CREATE TABLE $TABLE_NAME (
                $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COLUMN_KEY TEXT,
                $COLUMN_PACKAGE_NAME TEXT NOT NULL,
                $COLUMN_APP_NAME TEXT,
                $COLUMN_TITLE TEXT,
                $COLUMN_TEXT TEXT,
                $COLUMN_POST_TIME INTEGER NOT NULL,
                $COLUMN_IS_READ INTEGER NOT NULL DEFAULT 0,
                $COLUMN_READ_AT INTEGER DEFAULT 0,
                $COLUMN_IS_ONGOING INTEGER DEFAULT 0
            )
        """.trimIndent()
        db.execSQL(createTableQuery)
        db.execSQL("CREATE INDEX idx_is_read ON $TABLE_NAME ($COLUMN_IS_READ)")
        db.execSQL("CREATE INDEX idx_post_time ON $TABLE_NAME ($COLUMN_POST_TIME)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_NAME")
        onCreate(db)
    }

    @Synchronized
    fun isNotificationAlreadySaved(
        key: String,
        packageName: String,
        title: String,
        text: String,
        postTime: Long
    ): Boolean {
        val db = readableDatabase

        // 1. Tarkistetaan suoraan avaimella (notification_key), riippumatta onko lukematon vai luettu
        if (key.isNotBlank()) {
            val cursor = db.query(
                TABLE_NAME,
                arrayOf(COLUMN_ID),
                "$COLUMN_KEY = ?",
                arrayOf(key),
                null,
                null,
                null
            )
            cursor.use {
                if (it.moveToFirst()) return true
            }
        }

        // 2. Tarkistetaan samansisältöinen viesti samalta sovellukselta (sama otsikko, teksti ja aikaleima +-3s)
        if (packageName.isNotBlank()) {
            val timeMargin = 3000L
            val minTime = postTime - timeMargin
            val maxTime = postTime + timeMargin
            val cursor = db.query(
                TABLE_NAME,
                arrayOf(COLUMN_ID),
                "$COLUMN_PACKAGE_NAME = ? AND $COLUMN_TITLE = ? AND $COLUMN_TEXT = ? AND $COLUMN_POST_TIME BETWEEN ? AND ?",
                arrayOf(packageName, title, text, minTime.toString(), maxTime.toString()),
                null,
                null,
                null
            )
            cursor.use {
                if (it.moveToFirst()) return true
            }
        }

        return false
    }

    @Synchronized
    fun insertNotification(
        key: String,
        packageName: String,
        appName: String,
        title: String,
        text: String,
        postTime: Long,
        isOngoing: Boolean
    ): Long {
        val db = writableDatabase

        // Check if there's already an unread notification with the exact same key or same content within 3 seconds
        val cursor = db.query(
            TABLE_NAME,
            arrayOf(COLUMN_ID, COLUMN_IS_READ),
            "$COLUMN_KEY = ? AND $COLUMN_IS_READ = 0",
            arrayOf(key),
            null,
            null,
            null
        )

        var existingId: Long = -1
        cursor.use {
            if (it.moveToFirst()) {
                existingId = it.getLong(it.getColumnIndexOrThrow(COLUMN_ID))
            }
        }

        val values = ContentValues().apply {
            put(COLUMN_KEY, key)
            put(COLUMN_PACKAGE_NAME, packageName)
            put(COLUMN_APP_NAME, appName)
            put(COLUMN_TITLE, title)
            put(COLUMN_TEXT, text)
            put(COLUMN_POST_TIME, postTime)
            put(COLUMN_IS_READ, 0)
            put(COLUMN_IS_ONGOING, if (isOngoing) 1 else 0)
        }

        return if (existingId != -1L) {
            // Update existing unread notification
            db.update(TABLE_NAME, values, "$COLUMN_ID = ?", arrayOf(existingId.toString()))
            existingId
        } else {
            // Insert new notification record
            db.insert(TABLE_NAME, null, values)
        }
    }

    @Synchronized
    fun getUnreadNotifications(): List<Map<String, Any?>> {
        val list = mutableListOf<Map<String, Any?>>()
        val db = readableDatabase
        val cursor = db.query(
            TABLE_NAME,
            null,
            "$COLUMN_IS_READ = 0",
            null,
            null,
            null,
            "$COLUMN_POST_TIME DESC"
        )

        cursor.use {
            while (it.moveToNext()) {
                list.add(cursorToMap(it))
            }
        }
        return list
    }

    @Synchronized
    fun getAllNotifications(): List<Map<String, Any?>> {
        val list = mutableListOf<Map<String, Any?>>()
        val db = readableDatabase
        val cursor = db.query(
            TABLE_NAME,
            null,
            null,
            null,
            null,
            null,
            "$COLUMN_POST_TIME DESC"
        )

        cursor.use {
            while (it.moveToNext()) {
                list.add(cursorToMap(it))
            }
        }
        return list
    }

    @Synchronized
    fun markAsRead(id: Long): Boolean {
        val db = writableDatabase
        val values = ContentValues().apply {
            put(COLUMN_IS_READ, 1)
            put(COLUMN_READ_AT, System.currentTimeMillis())
        }
        val affected = db.update(TABLE_NAME, values, "$COLUMN_ID = ?", arrayOf(id.toString()))
        return affected > 0
    }

    @Synchronized
    fun markAllAsRead(): Int {
        val db = writableDatabase
        val values = ContentValues().apply {
            put(COLUMN_IS_READ, 1)
            put(COLUMN_READ_AT, System.currentTimeMillis())
        }
        return db.update(TABLE_NAME, values, "$COLUMN_IS_READ = 0", null)
    }

    @Synchronized
    fun deleteNotification(id: Long): Boolean {
        val db = writableDatabase
        val affected = db.delete(TABLE_NAME, "$COLUMN_ID = ?", arrayOf(id.toString()))
        return affected > 0
    }

    @Synchronized
    fun clearAll(): Int {
        val db = writableDatabase
        return db.delete(TABLE_NAME, null, null)
    }

    @Synchronized
    fun clearRead(): Int {
        val db = writableDatabase
        return db.delete(TABLE_NAME, "$COLUMN_IS_READ = 1", null)
    }

    @Synchronized
    fun getStats(): Map<String, Any> {
        val db = readableDatabase
        var unread = 0
        var total = 0

        val unreadCursor = db.rawQuery("SELECT COUNT(*) FROM $TABLE_NAME WHERE $COLUMN_IS_READ = 0", null)
        unreadCursor.use {
            if (it.moveToFirst()) unread = it.getInt(0)
        }

        val totalCursor = db.rawQuery("SELECT COUNT(*) FROM $TABLE_NAME", null)
        totalCursor.use {
            if (it.moveToFirst()) total = it.getInt(0)
        }

        return mapOf(
            "unreadCount" to unread,
            "totalCount" to total
        )
    }

    @Synchronized
    fun getReadCount(): Int {
        val db = readableDatabase
        var count = 0
        val cursor = db.rawQuery("SELECT COUNT(*) FROM $TABLE_NAME WHERE $COLUMN_IS_READ = 1", null)
        cursor.use {
            if (it.moveToFirst()) count = it.getInt(0)
        }
        return count
    }

    @Synchronized
    fun getTotalCount(): Int {
        val db = readableDatabase
        var count = 0
        val cursor = db.rawQuery("SELECT COUNT(*) FROM $TABLE_NAME", null)
        cursor.use {
            if (it.moveToFirst()) count = it.getInt(0)
        }
        return count
    }

    @Synchronized
    fun insertBatchTestMessages(count: Int, markAsRead: Boolean): Int {
        val db = writableDatabase
        db.beginTransaction()
        try {
            val now = System.currentTimeMillis()
            for (i in 1..count) {
                val values = ContentValues().apply {
                    put(COLUMN_KEY, "test_batch_${now}_$i")
                    put(COLUMN_PACKAGE_NAME, "com.metait.test")
                    put(COLUMN_APP_NAME, "TestiSovellus")
                    put(COLUMN_TITLE, "Testiviesti #$i")
                    put(COLUMN_TEXT, "Tämä on testisovelluksen historiaviesti nro $i.")
                    put(COLUMN_POST_TIME, now - (count - i) * 1000)
                    put(COLUMN_IS_READ, if (markAsRead) 1 else 0)
                    put(COLUMN_READ_AT, if (markAsRead) now else 0)
                    put(COLUMN_IS_ONGOING, 0)
                }
                db.insert(TABLE_NAME, null, values)
            }
            db.setTransactionSuccessful()
            return count
        } finally {
            db.endTransaction()
        }
    }

    private fun cursorToMap(cursor: android.database.Cursor): Map<String, Any?> {
        return mapOf(
            "id" to cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_ID)),
            "key" to cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_KEY)),
            "packageName" to cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_PACKAGE_NAME)),
            "appName" to cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_APP_NAME)),
            "title" to cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_TITLE)),
            "text" to cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_TEXT)),
            "postTime" to cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_POST_TIME)),
            "isRead" to (cursor.getInt(cursor.getColumnIndexOrThrow(COLUMN_IS_READ)) == 1),
            "readAt" to cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_READ_AT)),
            "isOngoing" to (cursor.getInt(cursor.getColumnIndexOrThrow(COLUMN_IS_ONGOING)) == 1)
        )
    }
}
