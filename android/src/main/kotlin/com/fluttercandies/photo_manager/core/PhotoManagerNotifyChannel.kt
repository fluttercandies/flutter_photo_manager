package com.fluttercandies.photo_manager.core

import android.content.ContentResolver
import android.content.Context
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.MediaStore.Files.FileColumns.*
import com.fluttercandies.photo_manager.core.utils.IDBUtils
import com.fluttercandies.photo_manager.util.LogUtils
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

@Suppress("Range")
class PhotoManagerNotifyChannel(
    val applicationContext: Context,
    messenger: BinaryMessenger,
    handler: Handler
) {
    private var notifying = false

    private val videoObserver = MediaObserver(MEDIA_TYPE_VIDEO, handler)
    private val imageObserver = MediaObserver(MEDIA_TYPE_IMAGE, handler)
    private val audioObserver = MediaObserver(MEDIA_TYPE_AUDIO, handler)
    private val allUri = IDBUtils.allUri
    private val imageUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
    private val videoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
    private val audioUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

    private val methodChannel = MethodChannel(messenger, "com.fluttercandies/photo_manager/notify")

    private val context
        get() = applicationContext

    fun startNotify() {
        if (notifying) {
            return
        }
        registerObserver(imageObserver, imageUri)
        registerObserver(videoObserver, videoUri)
        registerObserver(audioObserver, audioUri)

        notifying = true
    }

    private fun registerObserver(mediaObserver: MediaObserver, uri: Uri) {
        context.contentResolver.registerContentObserver(uri, true, mediaObserver)
        mediaObserver.uri = uri
    }

    fun stopNotify() {
        if (!notifying) {
            return
        }
        notifying = false
        context.contentResolver.unregisterContentObserver(imageObserver)
        context.contentResolver.unregisterContentObserver(videoObserver)
        context.contentResolver.unregisterContentObserver(audioObserver)
    }

    fun onOuterChange(
        uri: Uri?,
        changeType: String,
        id: Long?,
        galleryId: Long?,
        observerType: Int
    ) {
        val resultMap = hashMapOf<String, Any?>(
            "platform" to "android",
            "uri" to uri.toString(),
            "type" to changeType,
            "mediaType" to observerType
        )
        if (id != null) {
            resultMap["id"] = id
        }
        if (galleryId != null) {
            resultMap["galleryId"] = galleryId
        }

        LogUtils.debug(resultMap)
        methodChannel.invokeMethod("change", resultMap)
    }

    fun setAndroidQExperimental(open: Boolean) {
        methodChannel.invokeMethod("setAndroidQExperimental", mapOf("open" to open))
    }

    private inner class MediaObserver(
        val type: Int,
        handler: Handler = Handler(Looper.getMainLooper())
    ) : ContentObserver(handler) {
        @Suppress("UseKtx")
        var uri: Uri = Uri.parse("content://${MediaStore.AUTHORITY}")

        val context: Context
            get() = applicationContext

        val cr: ContentResolver
            get() = context.contentResolver

        // ContentObserver callbacks run on the handler thread. When
        // MediaProvider rejects the query with "Volume <name> not found" on
        // devices where the primary volume is transiently unavailable, letting
        // it propagate would crash that thread. Downgrade only that specific
        // IllegalArgumentException to a null cursor so the change notification
        // is dropped for this event; other IllegalArgumentException causes
        // (bad projection, unauthorized column, etc.) still surface.
        private fun safeQuery(
            uri: Uri,
            projection: Array<String>,
            selection: String,
            selectionArgs: Array<String>
        ): Cursor? = try {
            cr.query(uri, projection, selection, selectionArgs, null)
        } catch (e: IllegalArgumentException) {
            if (IDBUtils.isVolumeNotFound(e)) {
                LogUtils.error("MediaStore observer query hit missing volume, dropping event", e)
                null
            } else {
                throw e
            }
        }

        override fun onChange(selfChange: Boolean, uri: Uri?) {
            // Dispatch target on frameworks below API 30, which have no
            // change-kind flags; the type is inferred from the row state.
            handleOnChange(uri, null)
        }

        override fun onChange(selfChange: Boolean, uri: Uri?, flags: Int) {
            // Dispatch target on API 30+, where MediaProvider tags row
            // notifications with the kind of change. Untagged notifications
            // (flags without any kind bit, e.g. plain
            // ContentResolver#notifyChange calls) fall back to the row-state
            // inference used pre-30.
            val kind = flags and (
                ContentResolver.NOTIFY_INSERT
                    or ContentResolver.NOTIFY_UPDATE
                    or ContentResolver.NOTIFY_DELETE
                )
            handleOnChange(
                uri,
                when (kind) {
                    ContentResolver.NOTIFY_INSERT -> "insert"
                    ContentResolver.NOTIFY_UPDATE -> "update"
                    ContentResolver.NOTIFY_DELETE -> "delete"
                    else -> null
                },
            )
        }

        private fun handleOnChange(uri: Uri?, authoritativeType: String?) {
            if (uri == null) {
                return
            }
            val last = uri.lastPathSegment
            val id = last?.toLongOrNull()

            if (id == null) { // collection-level change
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    if (uri == this.uri) {
                        onOuterChange(uri, "insert", null, null, type)
                        return
                    }
                }
                onOuterChange(uri, "delete", null, null, type)
                return
            }

            if (authoritativeType == "delete") {
                // The row is gone; no point in querying it.
                onOuterChange(uri, "delete", id, null, type)
                return
            }

            val cursor = safeQuery(
                allUri,
                arrayOf(DATE_ADDED, DATE_MODIFIED, MEDIA_TYPE),
                "$_ID = ?",
                arrayOf(id.toString())
            )
            cursor?.use {
                if (!it.moveToNext()) {
                    // The row is not visible to this app. On Android 10+,
                    // rows inserted by other packages — such as files pushed
                    // via `adb push` or desktop drag-and-drop to an emulator
                    // — stay pending and hidden until their owner publishes
                    // them (#1443). An INSERT flag still proves an insert,
                    // but every other invisible outcome (a trashed row, a
                    // still-pending row being updated, a real deletion with
                    // an untagged notification) is reported as "delete",
                    // matching the historical behavior for missing rows.
                    val typeString =
                        if (authoritativeType == "insert") "insert" else "delete"
                    onOuterChange(uri, typeString, id, null, type)
                    return
                }
                // Find date to determine insert or update for untagged events.
                val typeString = authoritativeType ?: run {
                    val addTimestampSecond = it.getLong(it.getColumnIndex(DATE_ADDED))

                    // Within 30s, it is considered to be inserted, if it is exceeded, it is considered to be changed
                    if (System.currentTimeMillis() / 1000 - addTimestampSecond < 30) {
                        "insert"
                    } else {
                        "update"
                    }
                }
                // get Type
                val mediaType = it.getInt(it.getColumnIndex(MEDIA_TYPE))
                val (gId, _) = getGalleryIdAndName(id, mediaType)

                // The gallery may fail to resolve in racy cases; galleryId
                // is optional in the payload, so still deliver the event.
                onOuterChange(uri, typeString, id, gId, mediaType)
            }
        }

        private fun getGalleryIdAndName(id: Long, type: Int): Pair<Long?, String?> {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                    val cursor = safeQuery(
                        allUri,
                        arrayOf(
                            BUCKET_ID,
                            BUCKET_DISPLAY_NAME
                        ),
                        "$_ID = ?",
                        arrayOf(id.toString())
                    )
                    cursor?.use {
                        if (cursor.moveToNext()) {
                            val galleryId = cursor.getLong(
                                cursor.getColumnIndex(BUCKET_ID)
                            )
                            val galleryName = cursor.getString(
                                cursor.getColumnIndex(BUCKET_DISPLAY_NAME)
                            )
                            return Pair(galleryId, galleryName)
                        }
                    }
                }

                type == MEDIA_TYPE_AUDIO -> {
                    val cursor = safeQuery(
                        allUri,
                        arrayOf(
                            MediaStore.Audio.AudioColumns.ALBUM_ID,
                            ALBUM
                        ),
                        "$_ID = ?",
                        arrayOf(id.toString())
                    )
                    cursor?.use {
                        if (cursor.moveToNext()) {
                            val galleryId = cursor.getLong(
                                cursor.getColumnIndex(MediaStore.Audio.AudioColumns.ALBUM_ID)
                            )
                            val galleryName = cursor.getString(
                                cursor.getColumnIndex(ALBUM)
                            )
                            return Pair(galleryId, galleryName)
                        }
                    }
                }

                else -> {
                    val cursor = safeQuery(
                        allUri,
                        arrayOf("bucket_id", "bucket_display_name"),
                        "$_ID = ?",
                        arrayOf(id.toString())
                    )
                    cursor?.use {
                        if (cursor.moveToNext()) {
                            val galleryId = cursor.getLong(cursor.getColumnIndex("bucket_id"))
                            val galleryName =
                                cursor.getString(cursor.getColumnIndex("bucket_display_name"))
                            return Pair(galleryId, galleryName)
                        }
                    }
                }
            }
            return Pair(null, null)
        }
    }
}
