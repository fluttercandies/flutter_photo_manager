package com.fluttercandies.photo_manager.extension

import java.io.File

/**
 * Create the directory if it's not exist.
 */
fun String.checkDirs() {
    val targetFile = File(this)
    if (!targetFile.parentFile!!.exists()) {
        targetFile.parentFile!!.mkdirs()
    }
}
