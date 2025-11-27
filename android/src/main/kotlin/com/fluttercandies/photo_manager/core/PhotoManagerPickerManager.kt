package com.fluttercandies.photo_manager.core

import android.app.Activity
import android.content.ClipData
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.annotation.RequiresApi
import androidx.exifinterface.media.ExifInterface
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.utils.ConvertUtils
import com.fluttercandies.photo_manager.util.LogUtils
import com.fluttercandies.photo_manager.util.ResultHandler
import io.flutter.plugin.common.PluginRegistry

/**
 * Manager for handling native photo picker operations on Android.
 * Uses MediaStore.ACTION_PICK_IMAGES on Android 13+ (API 33+) and
 * falls back to Intent.ACTION_OPEN_DOCUMENT for older versions.
 * 
 * This picker does NOT require READ_MEDIA_IMAGES or READ_MEDIA_VIDEO permissions.
 */
class PhotoManagerPickerManager(
    private val context: Context,
    private var activity: Activity?
) : PluginRegistry.ActivityResultListener {

    companion object {
        private const val REQUEST_CODE_PHOTO_PICKER = 40080
        private const val REQUEST_CODE_OPEN_DOCUMENT = 40081
        
        // Cached max pick limit to avoid repeated system calls
        private var cachedMaxPickLimit: Int? = null
    }

    fun bindActivity(activity: Activity?) {
        this.activity = activity
    }

    private val cr: ContentResolver
        get() = context.contentResolver

    private var pickerHandler: ResultHandler? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_PHOTO_PICKER && requestCode != REQUEST_CODE_OPEN_DOCUMENT) {
            return false
        }

        if (resultCode == Activity.RESULT_OK && data != null) {
            handlePickerResult(data)
        } else {
            // User cancelled or no result
            pickerHandler?.reply(mapOf("data" to emptyList<Map<String, Any?>>()))
        }
        pickerHandler = null
        return true
    }

    private fun handlePickerResult(data: Intent) {
        PhotoManagerPlugin.runOnBackground {
            try {
                val uris = mutableListOf<Uri>()
                
                // Handle single or multiple selection
                val clipData: ClipData? = data.clipData
                if (clipData != null) {
                    // Multiple selection
                    for (i in 0 until clipData.itemCount) {
                        clipData.getItemAt(i)?.uri?.let { uris.add(it) }
                    }
                } else {
                    // Single selection
                    data.data?.let { uris.add(it) }
                }

                val assets = uris.mapNotNull { uri ->
                    try {
                        getAssetEntityFromUri(uri)
                    } catch (e: Exception) {
                        LogUtils.error("Failed to get asset from URI: $uri", e)
                        null
                    }
                }

                val result = ConvertUtils.convertAssets(assets)
                pickerHandler?.reply(result)
            } catch (e: Exception) {
                LogUtils.error("Failed to handle picker result", e)
                pickerHandler?.replyError(
                    "PICKER_ERROR",
                    "Failed to process picked files: ${e.message}"
                )
            }
        }
    }

    /**
     * Opens the native photo picker.
     * 
     * @param requestType The type of media to pick (1=image, 2=video, 3=both)
     * @param maxCount Maximum number of items to select. Use 1 for single selection.
     * @param resultHandler Callback with the result
     */
    fun openPhotoPicker(requestType: Int, maxCount: Int, resultHandler: ResultHandler) {
        if (activity == null) {
            resultHandler.replyError("ACTIVITY_NULL", "Activity is null, cannot open picker")
            return
        }

        this.pickerHandler = resultHandler

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                openPhotoPickerApi33(requestType, maxCount)
            } else {
                openDocumentPicker(requestType, maxCount)
            }
        } catch (e: Exception) {
            LogUtils.error("Failed to open photo picker", e)
            resultHandler.replyError("PICKER_ERROR", "Failed to open picker: ${e.message}")
            this.pickerHandler = null
        }
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun openPhotoPickerApi33(requestType: Int, maxCount: Int) {
        val intent = Intent(MediaStore.ACTION_PICK_IMAGES).apply {
            // Set media type filter
            type = when (requestType) {
                1 -> "image/*" // Images only
                2 -> "video/*" // Videos only
                else -> "*/*" // Both images and videos (common)
            }
            
            // For multiple selection, set the max count
            if (maxCount > 1) {
                putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, maxCount.coerceAtMost(getCachedMaxPickLimit()))
            }
        }
        
        activity?.startActivityForResult(intent, REQUEST_CODE_PHOTO_PICKER)
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun getCachedMaxPickLimit(): Int {
        return cachedMaxPickLimit ?: try {
            MediaStore.getPickImagesMaxLimit().also { cachedMaxPickLimit = it }
        } catch (e: Exception) {
            // Fallback to default value if method is not available
            100
        }
    }

    private fun openDocumentPicker(requestType: Int, maxCount: Int) {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            
            // Set media type filter
            type = when (requestType) {
                1 -> "image/*" // Images only
                2 -> "video/*" // Videos only
                else -> "*/*" // Both images and videos
            }
            
            // For filtering to both images and videos when requestType includes both
            if (requestType == 3) {
                val mimeTypes = arrayOf("image/*", "video/*")
                putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
            }
            
            // Allow multiple selection
            if (maxCount > 1) {
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            }
        }
        
        activity?.startActivityForResult(intent, REQUEST_CODE_OPEN_DOCUMENT)
    }

    /**
     * Creates an AssetEntity from a content URI obtained from the picker.
     * This extracts metadata from the content without requiring storage permissions.
     */
    private fun getAssetEntityFromUri(uri: Uri): AssetEntity? {
        // Get basic info from content resolver
        val cursor: Cursor? = cr.query(
            uri,
            null,
            null,
            null,
            null
        )

        var displayName = ""
        var createDate: Long? = null
        var modifiedDate: Long? = null
        
        cursor?.use {
            if (it.moveToFirst()) {
                val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1) {
                    displayName = it.getString(nameIndex) ?: ""
                }
                
                // Try to get date information from the cursor
                val dateModifiedIndex = it.getColumnIndex(MediaStore.MediaColumns.DATE_MODIFIED)
                if (dateModifiedIndex != -1) {
                    modifiedDate = it.getLong(dateModifiedIndex)
                }
                
                val dateAddedIndex = it.getColumnIndex(MediaStore.MediaColumns.DATE_ADDED)
                if (dateAddedIndex != -1) {
                    createDate = it.getLong(dateAddedIndex)
                }
            }
        }

        // Determine MIME type - use ContentResolver.getType as primary method
        // since MediaStore.MediaColumns.MIME_TYPE may not be available for external URIs
        val mimeType = cr.getType(uri)
        
        val type = when {
            mimeType?.startsWith("image/") == true -> 1
            mimeType?.startsWith("video/") == true -> 2
            mimeType?.startsWith("audio/") == true -> 3
            else -> 0
        }

        var width = 0
        var height = 0
        var duration = 0L
        var orientation = 0
        val fallbackTimestamp = System.currentTimeMillis() / 1000

        // Extract metadata based on type
        try {
            when (type) {
                1 -> {
                    // Image - extract dimensions and date from EXIF
                    cr.openInputStream(uri)?.use { inputStream ->
                        val exif = ExifInterface(inputStream)
                        width = exif.getAttributeInt(ExifInterface.TAG_IMAGE_WIDTH, 0)
                        height = exif.getAttributeInt(ExifInterface.TAG_IMAGE_LENGTH, 0)
                        orientation = exif.rotationDegrees
                        
                        // Try to get creation date from EXIF if not available from cursor
                        if (createDate == null) {
                            exif.getAttribute(ExifInterface.TAG_DATETIME_ORIGINAL)?.let { dateStr ->
                                try {
                                    val sdf = java.text.SimpleDateFormat("yyyy:MM:dd HH:mm:ss", java.util.Locale.US)
                                    createDate = sdf.parse(dateStr)?.time?.div(1000)
                                } catch (e: Exception) {
                                    // Ignore parse errors
                                }
                            }
                        }
                    }
                }
                2 -> {
                    // Video - extract metadata with MediaMetadataRetriever
                    val mmr = MediaMetadataRetriever()
                    try {
                        mmr.setDataSource(context, uri)
                        width = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                            ?.toInt() ?: 0
                        height = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                            ?.toInt() ?: 0
                        duration = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                            ?.toLong() ?: 0
                        orientation = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                            ?.toInt() ?: 0
                        
                        // Try to get creation date from video metadata if not available
                        if (createDate == null) {
                            mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DATE)?.let { dateStr ->
                                try {
                                    // Video date format is typically "yyyyMMddTHHmmss.SSSZ" or similar
                                    val sdf = java.text.SimpleDateFormat("yyyyMMdd'T'HHmmss", java.util.Locale.US)
                                    createDate = sdf.parse(dateStr)?.time?.div(1000)
                                } catch (e: Exception) {
                                    // Ignore parse errors
                                }
                            }
                        }
                    } finally {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            mmr.close()
                        } else {
                            mmr.release()
                        }
                    }
                }
            }
        } catch (e: Exception) {
            LogUtils.error("Failed to extract metadata from URI: $uri", e)
        }

        // Generate a unique ID using combination of URI string hash, length, and counter
        // to minimize collision risk. The counter adds temporal uniqueness for same-session picks.
        val uriStr = uri.toString()
        val baseHash = uriStr.hashCode().toLong()
        val lengthComponent = uriStr.length.toLong() shl 16
        val counterComponent = (System.nanoTime() and 0xFFFF)
        val id = ((baseHash xor lengthComponent) + counterComponent).let { value ->
            // Use absoluteValue for safe handling of Long.MIN_VALUE edge case
            if (value == Long.MIN_VALUE) Long.MAX_VALUE else kotlin.math.abs(value)
        }

        // Use extracted dates or fall back to current timestamp
        val finalCreateDate = createDate ?: fallbackTimestamp
        val finalModifiedDate = modifiedDate ?: finalCreateDate

        return AssetEntity(
            id = id,
            path = uri.toString(),
            duration = duration,
            createDt = finalCreateDate,
            width = width,
            height = height,
            type = type,
            displayName = displayName,
            modifiedDate = finalModifiedDate,
            orientation = orientation,
            isFavorite = false,
            androidQRelativePath = null,
            mimeType = mimeType
        )
    }
}
