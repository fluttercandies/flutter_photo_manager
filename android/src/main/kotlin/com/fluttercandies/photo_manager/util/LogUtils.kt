package com.fluttercandies.photo_manager.util

import android.database.Cursor
import android.util.Log

object LogUtils {
    const val TAG = "PhotoManager"
    var isLog = false

    @JvmStatic
    fun info(`object`: Any?) {
        if (!isLog) {
            return
        }
        val msg: String = `object`?.toString() ?: "null"
        Log.i(TAG, msg)
    }

    @JvmStatic
    fun debug(`object`: Any?) {
        if (!isLog) {
            return
        }
        val msg: String = `object`?.toString() ?: "null"
        Log.d(TAG, msg)
    }

    @JvmStatic
    fun error(`object`: Any?, error: Throwable?) {
        if (!isLog) {
            return
        }
        val msg: String =
            (if (`object` is Exception) `object`.localizedMessage else `object`?.toString())
                ?: "null"
        Log.e(TAG, msg, error)
    }

    @JvmStatic
    fun error(`object`: Any?) {
        if (!isLog) {
            return
        }
        val msg: String =
            (if (`object` is Exception) `object`.localizedMessage else `object`?.toString())
                ?: "null"
        Log.e(TAG, msg)
    }

    @JvmStatic
    fun logCursor(cursor: Cursor?, idKey: String? = "_id") {
        if (cursor == null) {
            debug("The cursor is null")
            return
        }
        debug("The cursor row: " + cursor.count)
        cursor.moveToPosition(-1)
        while (cursor.moveToNext()) {
            val stringBuilder = StringBuilder()
            val idIndex = cursor.getColumnIndex(idKey)
            if (idIndex != -1) {
                val idValue = cursor.getString(idIndex)
                stringBuilder.append("\nid: ")
                    .append(idValue)
                    .append("\n")
            }
            for (columnName in cursor.columnNames) {
                var value: String?
                val columnIndex = cursor.getColumnIndex(columnName)
                value = try {
                    cursor.getString(columnIndex)
                } catch (e: Exception) {
                    e.printStackTrace()
                    val blob = cursor.getBlob(columnIndex)
                    "blob(" + blob.size + ")"
                }
                if (!columnName.equals(idKey, ignoreCase = true)) {
                    stringBuilder.append("|--")
                        .append(columnName)
                        .append(" : ")
                        .append(value)
                        .append("\n")
                }
            }
            debug(stringBuilder)
        }
        cursor.moveToPosition(-1)
    }
}