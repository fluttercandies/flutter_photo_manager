package com.fluttercandies.photo_manager.core.utils

import android.os.Build
import android.os.Environment
import androidx.exifinterface.media.ExifInterface
import java.io.File
import java.io.InputStream

/**
 * Create the directory if it's not exist.
 */
fun String.checkDirs() {
    val targetFile = File(this)
    if (!targetFile.parentFile!!.exists()) {
        targetFile.parentFile!!.mkdirs()
    }
}

fun InputStream.getOrientationDegrees(): Int {
    return try {
        this.use {
            return@use ExifInterface(it).rotationDegrees
        }
    } catch (ignored: Throwable) {
        0
    }
}

fun isExternalStorageLegacy(): Boolean {
    return Build.VERSION.SDK_INT == Build.VERSION_CODES.Q && Environment.isExternalStorageLegacy()
}
