package com.fluttercandies.photo_manager.core.entity

import android.graphics.Bitmap

data class ThumbLoadOption(
    val width: Int,
    val height: Int,
    val format: Bitmap.CompressFormat,
    val quality: Int,
    val frame: Long,
) {
    companion object Factory {
        fun fromMap(map: Map<*, *>): ThumbLoadOption {
            val width = map["width"] as Int
            val height = map["height"] as Int
            val format = map["format"] as Int
            val quality = map["quality"] as Int
            val frame = (map["frame"] as Int).toLong()

            val compressFormat = if (format == 0) {
                Bitmap.CompressFormat.JPEG
            } else {
                Bitmap.CompressFormat.PNG
            }

            return ThumbLoadOption(width, height, compressFormat, quality, frame)
        }
    }
}
