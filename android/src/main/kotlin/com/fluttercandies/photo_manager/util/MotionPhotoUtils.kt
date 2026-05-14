// AIGC START
package com.fluttercandies.photo_manager.util

import androidx.exifinterface.media.ExifInterface
import java.io.InputStream

/**
 * Detects Android Motion Photo via XMP metadata.
 * Uses Camera:MotionPhoto (1) or legacy MicroVideo (1) per
 * https://developer.android.com/media/platform/motion-photo-format
 */
object MotionPhotoUtils {
    /** Same as Dart _livePhotosType; used so Android motion photo is treated as isLivePhoto. */
    const val SUBTYPE_LIVE_PHOTO = 1 shl 3
    const val XMP_READ_LIMIT = 256 * 1024

    /**
     * Returns live photo subtype (SUBTYPE_LIVE_PHOTO) if the image is a motion photo, else 0.
     */
    @JvmStatic
    fun getMotionPhotoSubtype(exif: ExifInterface): Int {
        return if (isMotionPhoto(exif)) SUBTYPE_LIVE_PHOTO else 0
    }

    /**
     * Returns true if EXIF/XMP indicates Motion Photo (MotionPhoto=1 or MicroVideo=1).
     * Tries ExifInterface attributes first, then raw XMP byte search (custom XMP may not be exposed).
     */
    @JvmStatic
    fun isMotionPhoto(exif: ExifInterface): Boolean {
        // Camera:MotionPhoto = 1 (current format)
        if (exif.getAttributeInt("MotionPhoto", 0) == 1) return true
        if (exif.getAttribute("MotionPhoto") == "1") return true
        // Legacy MicroVideo = 1
        if (exif.getAttributeInt("MicroVideo", 0) == 1) return true
        if (exif.getAttribute("MicroVideo") == "1") return true
        return false
    }

    /**
     * Detects motion photo by reading raw bytes (XMP segment) when ExifInterface does not expose the tag.
     */
    @JvmStatic
    fun isMotionPhotoFromStream(stream: InputStream): Boolean {
        val buf = ByteArray(XMP_READ_LIMIT)
        val n = stream.read(buf)
        if (n <= 0) return false
        val str = String(buf, 0, n, Charsets.UTF_8)
        // XMP often: MotionPhoto="1" or MicroVideo="1"
        if (str.contains("MotionPhoto") && valueEqualsOneInXmp(str, "MotionPhoto")) return true
        if (str.contains("MicroVideo") && valueEqualsOneInXmp(str, "MicroVideo")) return true
        return false
    }

    private fun valueEqualsOneInXmp(xmp: String, tag: String): Boolean {
        val idx = xmp.indexOf(tag)
        if (idx < 0) return false
        val after = xmp.substring(idx.coerceAtMost(xmp.length - 1), minOf(idx + 80, xmp.length))
        return after.contains("=\"1\"") || after.contains("='1'") || after.contains(">1<")
    }
}
// AIGC END
