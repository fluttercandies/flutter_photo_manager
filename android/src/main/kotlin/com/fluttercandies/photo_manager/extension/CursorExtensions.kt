@file:Suppress("Range","unused")

package com.fluttercandies.photo_manager.extension

import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.BaseColumns._ID
import android.provider.MediaStore
import android.provider.MediaStore.MediaColumns.DATA
import android.provider.MediaStore.MediaColumns.DATE_ADDED
import android.provider.MediaStore.MediaColumns.DATE_MODIFIED
import android.provider.MediaStore.MediaColumns.DATE_TAKEN
import android.provider.MediaStore.MediaColumns.DISPLAY_NAME
import android.provider.MediaStore.MediaColumns.DURATION
import android.provider.MediaStore.MediaColumns.HEIGHT
import android.provider.MediaStore.MediaColumns.IS_FAVORITE
import android.provider.MediaStore.MediaColumns.MIME_TYPE
import android.provider.MediaStore.MediaColumns.ORIENTATION
import android.provider.MediaStore.MediaColumns.RELATIVE_PATH
import android.provider.MediaStore.MediaColumns.WIDTH
import androidx.exifinterface.media.ExifInterface
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.utils.IDBUtils.Companion.isAboveAndroidQ
import com.fluttercandies.photo_manager.core.utils.MediaStoreUtils
import com.fluttercandies.photo_manager.util.LogUtils
import com.fluttercandies.photo_manager.util.MotionPhotoUtils
import java.io.ByteArrayInputStream
import java.io.File

fun Cursor.getInt(columnName: String): Int {
    return getInt(getColumnIndex(columnName))
}

fun Cursor.getString(columnName: String): String {
    return when (val index = getColumnIndex(columnName)) {
        -1 -> ""
        else -> getString(index) ?: ""
    }
}

fun Cursor.getStringOrNull(columnName: String): String? {
    return when (val index = getColumnIndex(columnName)) {
        -1 -> null
        else -> getString(index)
    }
}

fun Cursor.getLong(columnName: String): Long {
    return getLong(getColumnIndex(columnName))
}

fun Cursor.getDouble(columnName: String): Double {
    return getDouble(getColumnIndex(columnName))
}

fun Cursor.toAssetEntity(
    context: Context,
    checkIfExists: Boolean = true,
    throwIfNotExists: Boolean = true,
    givenId: Long? = null,
): AssetEntity? {
    val id = givenId ?: getLong(_ID)
    val path = getString(DATA)
    if (checkIfExists && path.isNotBlank() && !File(path).exists()) {
        if (throwIfNotExists) {
            throwMsg("Asset ($id) does not exists at its path ($path).")
        }
        return null
    }

    val date = if (isAboveAndroidQ) {
        var tmpTime = getLong(DATE_TAKEN) / 1000
        if (tmpTime == 0L) {
            tmpTime = getLong(DATE_ADDED)
        }
        tmpTime
    } else getLong(DATE_ADDED)
    val type = getInt(MediaStore.Files.FileColumns.MEDIA_TYPE)
    val mimeType = getString(MIME_TYPE)
    val duration = if (type == MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE) 0
    else getLong(DURATION)
    var width = getInt(WIDTH)
    var height = getInt(HEIGHT)
    val displayName = getString(DISPLAY_NAME)
    val modifiedDate = getLong(DATE_MODIFIED)
    var orientation: Int = getInt(ORIENTATION)
    val isFavorite = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && getInt(IS_FAVORITE) == 1
    val relativePath: String? = if (isAboveAndroidQ) {
        getString(RELATIVE_PATH)
    } else null
    // AIGC START - motion photo (Android) subtype for isLivePhoto
    var imageSubtype = 0
    // AIGC END
    if (width == 0 || height == 0) {
        try {
            if (type == MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE && !mimeType.contains("svg")) {
                val uri = getUri(id, MediaStoreUtils.convertTypeToMediaType(type))
                context.contentResolver.openInputStream(uri)?.use { stream ->
                    val buf = ByteArray(MotionPhotoUtils.XMP_READ_LIMIT)
                    val n = stream.read(buf)
                    if (n > 0) {
                        val copy = buf.copyOf(n)
                        val exif = ExifInterface(ByteArrayInputStream(copy))
                        width = exif.getAttribute(ExifInterface.TAG_IMAGE_WIDTH)?.toInt() ?: width
                        height = exif.getAttribute(ExifInterface.TAG_IMAGE_LENGTH)?.toInt() ?: height
                        imageSubtype = MotionPhotoUtils.getMotionPhotoSubtype(exif)
                        if (imageSubtype == 0) {
                            imageSubtype = if (MotionPhotoUtils.isMotionPhotoFromStream(ByteArrayInputStream(copy))) MotionPhotoUtils.SUBTYPE_LIVE_PHOTO else 0
                        }
                    }
                }
            } else if (type == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) {
                val mmr = MediaMetadataRetriever()
                mmr.setDataSource(path)
                width = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                    ?.toInt() ?: 0
                height = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                    ?.toInt() ?: 0
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                    orientation =
                        mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                            ?.toInt()
                            ?: orientation
                }
                if (isAboveAndroidQ) mmr.close() else mmr.release()
            }
        } catch (e: Throwable) {
            LogUtils.error(e)
        }
    }
    // AIGC START - detect motion photo when width/height already set (no exif opened above)
    if (type == MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE && !mimeType.contains("svg") && imageSubtype == 0) {
        try {
            val uri = getUri(id, MediaStoreUtils.convertTypeToMediaType(type))
            context.contentResolver.openInputStream(uri)?.use { stream ->
                val buf = ByteArray(MotionPhotoUtils.XMP_READ_LIMIT)
                val n = stream.read(buf)
                if (n > 0) {
                    val copy = buf.copyOf(n)
                    val exif = ExifInterface(ByteArrayInputStream(copy))
                    imageSubtype = MotionPhotoUtils.getMotionPhotoSubtype(exif)
                    if (imageSubtype == 0) {
                        imageSubtype = if (MotionPhotoUtils.isMotionPhotoFromStream(ByteArrayInputStream(copy))) MotionPhotoUtils.SUBTYPE_LIVE_PHOTO else 0
                    }
                }
            }
        } catch (e: Throwable) {
            LogUtils.error(e)
        }
    }
    // AIGC END
    return AssetEntity(
        id,
        path,
        duration,
        date,
        width,
        height,
        MediaStoreUtils.convertTypeToMediaType(type),
        displayName,
        modifiedDate,
        orientation,
        isFavorite,
        androidQRelativePath = relativePath,
        mimeType = mimeType,
        subtype = imageSubtype
    )
}

@Throws(RuntimeException::class)
private fun throwMsg(msg: String): Nothing {
    throw RuntimeException(msg)
}

private fun getUri(id: Long, type: Int, isOrigin: Boolean = false): Uri {
    var uri = when (type) {
        1 -> ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
        2 -> ContentUris.withAppendedId(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id)
        3 -> ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
        else -> throwMsg("Unexpected asset type $type")
    }

    if (isOrigin) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            uri = MediaStore.setRequireOriginal(uri)
        }
    }

    return uri
}
