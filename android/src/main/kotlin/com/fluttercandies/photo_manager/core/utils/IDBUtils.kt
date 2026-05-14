package com.fluttercandies.photo_manager.core.utils

import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.MediaStore.MediaColumns.BUCKET_DISPLAY_NAME
import android.provider.MediaStore.MediaColumns.BUCKET_ID
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
import android.provider.MediaStore.MediaColumns.TITLE
import android.provider.MediaStore.MediaColumns.WIDTH
import android.provider.MediaStore.MediaColumns._ID
import android.provider.MediaStore.VOLUME_EXTERNAL
import androidx.annotation.ChecksSdkIntAtLeast
import androidx.exifinterface.media.ExifInterface
import com.fluttercandies.photo_manager.core.PhotoManager
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.entity.AssetPathEntity
import com.fluttercandies.photo_manager.core.entity.filter.FilterOption
import com.fluttercandies.photo_manager.extension.*
import com.fluttercandies.photo_manager.util.LogUtils
import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.net.URLConnection

@Suppress("Deprecation", "InlinedApi", "Range")
interface IDBUtils {
    companion object {
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.Q)
        val isAboveAndroidQ = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

        val storeImageKeys = mutableListOf(
            DISPLAY_NAME, // 显示的名字
            DATA, // 数据
            _ID, // id
            TITLE, // id
            BUCKET_ID, // dir id 目录
            BUCKET_DISPLAY_NAME, // dir name 目录名字
            WIDTH, // 宽
            HEIGHT, // 高
            ORIENTATION, // 角度
            DATE_ADDED, // 创建时间
            DATE_MODIFIED, // 修改时间
            MIME_TYPE, // mime type
            DATE_TAKEN //日期
        ).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) add(DATE_TAKEN) // 拍摄时间
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) add(IS_FAVORITE)
        }

        val storeVideoKeys = mutableListOf(
            DISPLAY_NAME, // 显示的名字
            DATA, // 数据
            _ID, // id
            TITLE, // id
            BUCKET_ID, // dir id 目录
            BUCKET_DISPLAY_NAME, // dir name 目录名字
            DATE_ADDED, // 创建时间
            WIDTH, // 宽
            HEIGHT, // 高
            ORIENTATION, // 角度
            DATE_MODIFIED, // 修改时间
            MIME_TYPE, // mime type
            DURATION //时长
        ).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) add(DATE_TAKEN) // 拍摄时间
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) add(IS_FAVORITE)
        }

        val typeKeys = arrayOf(
            MediaStore.Files.FileColumns.MEDIA_TYPE,
            MediaStore.Images.Media.DISPLAY_NAME
        )

        val storeBucketKeys = arrayOf(BUCKET_ID, BUCKET_DISPLAY_NAME)

        val allUri: Uri
            get() = MediaStore.Files.getContentUri(VOLUME_EXTERNAL)

    }

    fun keys(): Array<String>

    val idSelection: String
        get() = "${MediaStore.Images.Media._ID} = ?"

    val allUri: Uri
        get() = IDBUtils.allUri

    fun getAssetPathList(
        context: Context,
        requestType: Int = 0,
        option: FilterOption?
    ): List<AssetPathEntity>

    fun getAssetListPaged(
        context: Context,
        pathId: String,
        page: Int,
        size: Int,
        requestType: Int = 0,
        option: FilterOption?
    ): List<AssetEntity>

    fun getAssetListRange(
        context: Context,
        galleryId: String,
        start: Int,
        end: Int,
        requestType: Int,
        option: FilterOption?
    ): List<AssetEntity>

    fun getAssetEntity(context: Context, id: String, checkIfExists: Boolean = true): AssetEntity?

    fun getAssetPathEntityFromId(
        context: Context,
        pathId: String,
        type: Int,
        option: FilterOption?
    ): AssetPathEntity?

    fun saveImage(
        context: Context,
        bytes: ByteArray,
        filename: String,
        title: String,
        desc: String,
        relativePath: String,
        orientation: Int?,
        latitude: Double?,
        longitude: Double?,
        creationDate: Long?
    ): AssetEntity {
        var inputStream = ByteArrayInputStream(bytes)
        fun refreshStream() {
            inputStream = ByteArrayInputStream(bytes)
        }

        val typeFromStream: String = URLConnection.guessContentTypeFromName(filename)
            ?: inputStream.let {
                val type = URLConnection.guessContentTypeFromStream(inputStream)
                refreshStream()
                type
            }
            ?: "image/*"

        val exif = ExifInterface(inputStream)
        val (width, height) = Pair(
            exif.getAttributeInt(ExifInterface.TAG_IMAGE_WIDTH, 0),
            exif.getAttributeInt(ExifInterface.TAG_IMAGE_LENGTH, 0)
        )
        val (rotationDegrees, latLong) = Pair(
            orientation ?: if (isAboveAndroidQ) exif.rotationDegrees else 0,
            if (isAboveAndroidQ) {
                if (latitude != null && longitude != null) {
                    doubleArrayOf(latitude, longitude)
                } else null
            } else exif.latLong
        )
        refreshStream()

        val timestamp = System.currentTimeMillis() / 1000
        val values = ContentValues().apply {
            put(
                MediaStore.Files.FileColumns.MEDIA_TYPE,
                MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
            )
            put(MediaStore.Images.ImageColumns.DESCRIPTION, desc)
            put(DISPLAY_NAME, title)
            put(MIME_TYPE, typeFromStream)
            put(TITLE, title)
            put(DATE_ADDED, timestamp)
            put(DATE_MODIFIED, timestamp)
            put(WIDTH, width)
            put(HEIGHT, height)
            if (isAboveAndroidQ) {
                put(DATE_TAKEN, creationDate ?: (timestamp * 1000))
                put(ORIENTATION, rotationDegrees)
                if (relativePath.isNotBlank()) {
                    put(RELATIVE_PATH, relativePath)
                }
            }
            if (latLong != null) {
                put(MediaStore.Images.ImageColumns.LATITUDE, latLong.first())
                put(MediaStore.Images.ImageColumns.LONGITUDE, latLong.last())
            }
        }

        return insertUri(
            context,
            inputStream,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            values,
        )
    }

    fun saveImage(
        context: Context,
        filePath: String,
        title: String,
        desc: String,
        relativePath: String,
        orientation: Int?,
        latitude: Double?,
        longitude: Double?,
        creationDate: Long?
    ): AssetEntity {
        filePath.checkDirs()
        val file = File(filePath)
        var inputStream = FileInputStream(file)
        fun refreshStream() {
            inputStream = FileInputStream(file)
        }

        val typeFromStream: String = URLConnection.guessContentTypeFromName(title)
            ?: URLConnection.guessContentTypeFromName(filePath)
            ?: inputStream.let {
                val type = URLConnection.guessContentTypeFromStream(inputStream)
                refreshStream()
                type
            }
            ?: "image/*"

        val exif = ExifInterface(inputStream)
        val (width, height) = Pair(
            exif.getAttributeInt(ExifInterface.TAG_IMAGE_WIDTH, 0),
            exif.getAttributeInt(ExifInterface.TAG_IMAGE_LENGTH, 0)
        )
        val (rotationDegrees, latLong) = Pair(
            orientation ?: if (isAboveAndroidQ) exif.rotationDegrees else 0,
            if (isAboveAndroidQ) {
                if (latitude != null && longitude != null) {
                    doubleArrayOf(latitude, longitude)
                } else null
            } else exif.latLong
        )
        refreshStream()

        val shouldKeepPath = if (!isAboveAndroidQ) {
            val dir = Environment.getExternalStorageDirectory()
            file.absolutePath.startsWith(dir.path)
        } else false

        val timestamp = System.currentTimeMillis() / 1000
        val values = ContentValues().apply {
            put(
                MediaStore.Files.FileColumns.MEDIA_TYPE,
                MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
            )
            put(MediaStore.Images.ImageColumns.DESCRIPTION, desc)
            put(DISPLAY_NAME, title)
            put(MIME_TYPE, typeFromStream)
            put(TITLE, title)
            put(DATE_ADDED, timestamp)
            put(DATE_MODIFIED, timestamp)
            put(WIDTH, width)
            put(HEIGHT, height)
            if (isAboveAndroidQ) {
                put(DATE_TAKEN, creationDate ?: (timestamp * 1000))
                put(ORIENTATION, rotationDegrees)
                if (relativePath.isNotBlank()) {
                    put(RELATIVE_PATH, relativePath)
                }
            }
            if (latLong != null) {
                put(MediaStore.Images.ImageColumns.LATITUDE, latLong.first())
                put(MediaStore.Images.ImageColumns.LONGITUDE, latLong.last())
            }
            if (shouldKeepPath) {
                put(DATA, filePath)
            }
        }

        return insertUri(
            context,
            inputStream,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            values,
            shouldKeepPath
        )
    }

    /**
     * Save a Motion Photo by concatenating the image bytes and video bytes
     * into a single JPEG file, following the Android Motion Photo format 1.0.
     *
     * This method injects the required XMP metadata (Camera:MotionPhoto=1,
     * Container:Directory, etc.) so that the gallery app can recognize the file
     * as a Motion Photo.
     *
     * Specification: https://developer.android.com/media/platform/motion-photo-format
     */
    fun saveMotionPhoto(
        context: Context,
        imagePath: String,
        videoPath: String,
        title: String,
        desc: String,
        relativePath: String,
    ): AssetEntity {
        imagePath.checkDirs()
        videoPath.checkDirs()
        val imageFile = File(imagePath)
        val videoFile = File(videoPath)

        // Read image and video bytes
        val imageBytes = imageFile.readBytes()
        val videoBytes = videoFile.readBytes()

        // Create Motion Photo with XMP metadata using XmpWriter
        val inputStream = com.fluttercandies.photo_manager.util.XmpWriter.createMotionPhotoStream(
            imageBytes,
            videoBytes
        )

        // Ensure DISPLAY_NAME has a .jpg extension for proper MIME type detection
        val displayName = if (title.isNotBlank() &&
            !title.endsWith(".jpg", ignoreCase = true) &&
            !title.endsWith(".jpeg", ignoreCase = true)
        ) {
            "$title.jpg"
        } else if (title.isBlank()) {
            "${System.currentTimeMillis()}.jpg"
        } else {
            title
        }

        val typeFromStream: String = URLConnection.guessContentTypeFromName(displayName)
            ?: URLConnection.guessContentTypeFromName(imagePath)
            ?: "image/jpeg"

        // Read dimensions from the original image
        val exif = ExifInterface(ByteArrayInputStream(imageBytes))
        val (width, height) = Pair(
            exif.getAttributeInt(ExifInterface.TAG_IMAGE_WIDTH, 0),
            exif.getAttributeInt(ExifInterface.TAG_IMAGE_LENGTH, 0)
        )

        val timestamp = System.currentTimeMillis() / 1000
        val values = ContentValues().apply {
            put(
                MediaStore.Files.FileColumns.MEDIA_TYPE,
                MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
            )
            put(MediaStore.Images.ImageColumns.DESCRIPTION, desc)
            put(DISPLAY_NAME, displayName)
            put(MIME_TYPE, typeFromStream)
            put(TITLE, title.ifBlank { displayName })
            put(DATE_ADDED, timestamp)
            put(DATE_MODIFIED, timestamp)
            put(WIDTH, width)
            put(HEIGHT, height)
            if (isAboveAndroidQ) {
                put(DATE_TAKEN, timestamp * 1000)
                if (relativePath.isNotBlank()) {
                    put(RELATIVE_PATH, relativePath)
                }
            }
        }

        return insertUri(
            context,
            inputStream,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            values,
        )
    }

    fun saveVideo(
        context: Context,
        filePath: String,
        title: String,
        desc: String,
        relativePath: String,
        orientation: Int?,
        latitude: Double?,
        longitude: Double?,
        creationDate: Long?
    ): AssetEntity {
        filePath.checkDirs()
        val file = File(filePath)
        var inputStream = FileInputStream(file)
        fun refreshStream() {
            inputStream = FileInputStream(file)
        }

        val typeFromStream = URLConnection.guessContentTypeFromName(title)
            ?: URLConnection.guessContentTypeFromName(filePath)
            ?: inputStream.let {
                val type = URLConnection.guessContentTypeFromStream(inputStream)
                refreshStream()
                type
            }
            ?: "video/*"

        val info = VideoUtils.getPropertiesUseMediaPlayer(filePath)

        val (rotationDegrees, latLong) = ExifInterface(inputStream).let { exif ->
            Pair(
                orientation ?: if (isAboveAndroidQ) exif.rotationDegrees else 0,
                if (isAboveAndroidQ) {
                    if (latitude != null && longitude != null) {
                        doubleArrayOf(latitude, longitude)
                    } else null
                } else exif.latLong
            )
        }
        refreshStream()

        val shouldKeepPath = if (!isAboveAndroidQ) {
            val dir = Environment.getExternalStorageDirectory()
            file.absolutePath.startsWith(dir.path)
        } else false

        val timestamp = System.currentTimeMillis() / 1000
        val values = ContentValues().apply {
            put(
                MediaStore.Files.FileColumns.MEDIA_TYPE,
                MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
            )
            put(MediaStore.Video.VideoColumns.DESCRIPTION, desc)
            put(TITLE, title)
            put(DISPLAY_NAME, title)
            put(MIME_TYPE, typeFromStream)
            put(DATE_ADDED, timestamp)
            put(DATE_MODIFIED, timestamp)
            put(DURATION, info.duration)
            put(WIDTH, info.width)
            put(HEIGHT, info.height)
            if (isAboveAndroidQ) {
                put(DATE_TAKEN, creationDate ?: (timestamp * 1000))
                put(ORIENTATION, rotationDegrees)
                if (relativePath.isNotBlank()) {
                    put(RELATIVE_PATH, relativePath)
                }
            } else {
                val albumDir = File(
                    Environment.getExternalStorageDirectory().path,
                    Environment.DIRECTORY_MOVIES
                )
                // Check if the directory exist.
                File(albumDir, title).path.checkDirs()
                // Using a duplicate file name that already exists on the device will cause
                // inserts to fail on Android API 29-.
                val basename = System.currentTimeMillis().toString()
                val newFilePath = File(albumDir, "$basename.${file.extension}").absolutePath
                put(DATA, newFilePath)
            }
            if (latLong != null) {
                put(MediaStore.Video.VideoColumns.LATITUDE, latLong.first())
                put(MediaStore.Video.VideoColumns.LONGITUDE, latLong.last())
            }
            if (shouldKeepPath) {
                put(DATA, filePath)
            }
        }

        return insertUri(
            context,
            inputStream,
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            values,
            shouldKeepPath
        )
    }

    private fun insertUri(
        context: Context,
        inputStream: InputStream,
        contentUri: Uri,
        values: ContentValues,
        shouldKeepPath: Boolean = false,
    ): AssetEntity {
        val cr = context.contentResolver
        val uri = cr.insert(contentUri, values) ?: throwMsg("Cannot insert new asset.")
        val id = ContentUris.parseId(uri)
        if (!shouldKeepPath) {
            val outputStream = cr.openOutputStream(uri)
                ?: throwMsg("Cannot open the output stream for $uri.")
            outputStream.use { os -> inputStream.use { it.copyTo(os) } }
        }
        cr.notifyChange(uri, null)
        return getAssetEntity(context, id.toString()) ?: throwIdNotFound(id)
    }

    fun assetExists(context: Context, id: String): Boolean {
        val columns = arrayOf(_ID)
        context.contentResolver.logQuery(allUri, columns, "$_ID = ?", arrayOf(id), null).use {
            return it.count >= 1
        }
    }

    fun getFilePath(context: Context, id: String, origin: Boolean): String

    fun getExif(context: Context, id: String): ExifInterface?

    fun getLatLong(context: Context, id: String): DoubleArray? {
        val asset = getAssetEntity(context, id) ?: return null

        /// Apparently no LatLng for audios.
        if (asset.type == MediaStoreUtils.convertMediaTypeToType(MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO)) {
            return null;
        }

        // For videos, use MediaMetadataRetriever to extract location
        if (asset.type == MediaStoreUtils.convertMediaTypeToType(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO)) {
            return try {
                val retriever = MediaMetadataRetriever()
                retriever.setDataSource(asset.path)
                val location =
                    retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_LOCATION)
                retriever.release()

                // Location format is typically: "+37.4219-122.0840/" or "+37.4219-122.0840"
                // Parse the ISO 6709 format
                if (location != null) parseLocationString(location) else null
            } catch (e: Exception) {
                LogUtils.error(e)
                null
            }
        }

        // For images, use ExifInterface
        if (asset.type == MediaStoreUtils.convertMediaTypeToType(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE)) {
            return try {
                val exifInfo = getExif(context, id)
                exifInfo?.latLong
            } catch (e: Exception) {
                LogUtils.error(e)
                null
            }
        }

        return null
    }

    private fun parseLocationString(location: String): DoubleArray? {
        // ISO 6709 format: ±DD.DDDD±DDD.DDDD or ±DD.DDDD±DDD.DDDD/
        // Example: "+37.4219-122.0840/" or "+37.4219-122.0840"
        try {
            val cleanLocation = location.trimEnd('/')

            // Find where longitude starts (second + or -)
            var longitudeStartIndex = -1
            var signCount = 0
            for (i in cleanLocation.indices) {
                if (cleanLocation[i] == '+' || cleanLocation[i] == '-') {
                    signCount++
                    if (signCount == 2) {
                        longitudeStartIndex = i
                        break
                    }
                }
            }

            if (longitudeStartIndex > 0) {
                val latStr = cleanLocation.take(longitudeStartIndex)
                val lngStr = cleanLocation.substring(longitudeStartIndex)

                val latitude = latStr.toDoubleOrNull() ?: return null
                val longitude = lngStr.toDoubleOrNull() ?: return null

                return doubleArrayOf(latitude, longitude)
            }
        } catch (e: Exception) {
            LogUtils.error(e)
        }
        return null
    }

    fun getOriginBytes(
        context: Context,
        asset: AssetEntity,
        needLocationPermission: Boolean
    ): ByteArray

    fun getMediaUri(context: Context, id: Long, type: Int): String {
        val uri = getUri(id, type, false)
        return uri.toString()
    }

    fun getMainAssetPathEntity(
        context: Context,
        requestType: Int,
        option: FilterOption?
    ): List<AssetPathEntity>

    // Nullable for implementations.
    fun getSortOrder(start: Int, pageSize: Int, filterOption: FilterOption?): String? {
        val builder = StringBuilder()
        if (filterOption != null) {
            val orderBy = filterOption.orderByCondString()
            if (orderBy != null) {
                builder.append(orderBy)
                builder.append(" ")
            }
        }
        builder.append("LIMIT $pageSize OFFSET $start")
        return builder.toString()
    }

    fun copyToGallery(context: Context, assetId: String, galleryId: String): AssetEntity

    fun moveToGallery(context: Context, assetId: String, galleryId: String): AssetEntity

    fun getSomeInfo(context: Context, assetId: String): Pair<String, String?>?

    fun getUri(id: Long, type: Int, isOrigin: Boolean = false): Uri {
        var uri = when (type) {
            1 -> ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
            2 -> ContentUris.withAppendedId(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id)
            3 -> ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
            else -> throwMsg("Unexpected asset type $type")
        }

        if (isOrigin) {
            uri = MediaStore.setRequireOriginal(uri)
        }
        return uri
    }

    fun removeAllExistsAssets(context: Context): Boolean

    fun clearFileCache(context: Context) {}

    fun getAssetsPath(context: Context, ids: List<String>): List<String> {
        if (ids.count() > 500) {
            val result = ArrayList<String>()
            val total = ids.count()
            var count = total / 500
            if (total % 500 != 0) {
                count++
            }
            for (i in 0 until count) {
                val end = if (i == count - 1) {
                    ids.count()
                } else {
                    (i + 1) * 500 - 1
                }
                val start = i * 500

                val tmp = getAssetsPath(context, ids.subList(start, end))
                result.addAll(tmp)
            }
            return result
        }

        val key = arrayOf(_ID, MediaStore.Files.FileColumns.MEDIA_TYPE, DATA)
        val idSelection = ids.joinToString(",") { "?" }
        val selection = "$_ID in ($idSelection)"
        val cursor = context.contentResolver.logQuery(
            allUri,
            key,
            selection,
            ids.toTypedArray(),
            null
        )
        val list = ArrayList<String>()
        val map = HashMap<String, String>()
        cursor.use {
            while (it.moveToNext()) {
                val id = it.getString(_ID)
                val path = it.getString(DATA)
                map[id] = path
            }
        }
        for (id in ids) {
            map[id]?.let {
                list.add(it)
            }
        }
        return list
    }

    fun injectModifiedDate(context: Context, entity: AssetPathEntity) {
        getPathModifiedDate(context, entity.id)?.apply {
            entity.modifiedDate = this
        }
    }

    fun getPathRelativePath(context: Context, galleryId: String): String?

    fun getPathModifiedDate(context: Context, pathId: String): Long? {
        val columns = arrayOf(DATE_MODIFIED)
        val sortOrder = "$DATE_MODIFIED desc"
        val cursor = if (pathId == PhotoManager.ALL_ID) {
            context.contentResolver.logQuery(allUri, columns, null, null, sortOrder)
        } else {
            context.contentResolver.logQuery(
                allUri,
                columns,
                "$BUCKET_ID = ?",
                arrayOf(pathId),
                sortOrder
            )
        }
        cursor.use {
            if (it.moveToNext()) {
                return it.getLong(DATE_MODIFIED)
            }
        }
        return null
    }

    fun getColumnNames(context: Context): List<String> {
        val cr = context.contentResolver
        cr.logQuery(allUri, null, null, null, null).use {
            return it.columnNames.toList()
        }
    }

    fun getAssetCount(
        context: Context,
        option: FilterOption?,
        requestType: Int
    ): Int {
        val cr = context.contentResolver
        val args = ArrayList<String>()
        val where = option?.makeWhere(requestType, args, false)
            ?: RequestTypeUtils.toWhere(requestType)
        val order = option?.orderByCondString()
        cr.logQuery(allUri, arrayOf(_ID), where, args.toTypedArray(), order).use {
            return it.count
        }
    }

    fun getAssetCount(
        context: Context,
        option: FilterOption?,
        requestType: Int,
        galleryId: String,
    ): Int {
        val cr = context.contentResolver
        val args = ArrayList<String>()
        var where = option?.makeWhere(requestType, args, false)
            ?: RequestTypeUtils.toWhere(requestType)

        run {
            val result = StringBuilder()
            result.append(where)
            if (galleryId != PhotoManager.ALL_ID) {
                if (result.trim().isNotEmpty()) {
                    result.append(" AND ")
                }
                result.append("$BUCKET_ID = ?")
                args.add(galleryId)
            }

            where = result.toString()
        }

        val order = option?.orderByCondString()
        cr.logQuery(allUri, arrayOf(_ID), where, args.toTypedArray(), order).use {
            return it.count
        }
    }


    fun getAssetsByRange(
        context: Context,
        option: FilterOption?,
        start: Int,
        end: Int,
        requestType: Int
    ): List<AssetEntity> {
        val cr = context.contentResolver
        val args = ArrayList<String>()
        val where = option?.makeWhere(requestType, args, false)
            ?: RequestTypeUtils.toWhere(requestType)
        val order = option?.orderByCondString()
        cr.logQuery(allUri, keys(), where, args.toTypedArray(), order).use {
            val result = ArrayList<AssetEntity>()
            it.moveToPosition(start - 1)
            while (it.moveToNext()) {
                val asset = it.toAssetEntity(context, false) ?: continue
                result.add(asset)
                if (result.count() == end - start) {
                    break
                }
            }
            return result
        }
    }

    fun ContentResolver.logQuery(
        uri: Uri,
        projection: Array<String>?,
        selection: String?,
        selectionArgs: Array<String>?,
        sortOrder: String?
    ): Cursor {
        fun log(logFunc: (log: String) -> Unit, cursor: Cursor?) {
            if (LogUtils.isLog) {
                val sb = StringBuilder()
                sb.appendLine("uri: $uri")
                sb.appendLine("projection: ${projection?.joinToString(", ")}")
                sb.appendLine("selection: $selection")
                sb.appendLine("selectionArgs: ${selectionArgs?.joinToString(", ")}")
                sb.appendLine("sortOrder: $sortOrder")
                // format ? in selection and selectionArgs to display in log
                val sql = selection?.replace("?", "%s")?.format(*selectionArgs ?: emptyArray())
                sb.appendLine("sql: $sql")
                sb.appendLine("cursor count: ${cursor?.count}")
                logFunc(sb.toString())
            }
        }

        try {
            val cursor = query(uri, projection, selection, selectionArgs, sortOrder)
            log(LogUtils::info, cursor)
            return cursor ?: throwMsg("Failed to obtain the cursor.")
        } catch (e: Exception) {
            log(LogUtils::error, null)
            LogUtils.error("happen query error", e)
            throw e
        }
    }

    fun logRowWithId(context: Context, id: String) {
        if (LogUtils.isLog) {
            val splitter = "".padStart(40, '-')
            LogUtils.info("log error row $id start $splitter")
            val cursor = context.contentResolver.logQuery(
                allUri,
                null,
                "$_ID = ?",
                arrayOf(id),
                null
            )
            cursor.use {
                val names = it.columnNames
                if (it.moveToNext()) {
                    for (i in 0 until names.count()) {
                        LogUtils.info("${names[i]} : ${it.getString(i)}")
                    }
                }
            }
            LogUtils.info("log error row $id end $splitter")
        }
    }

    @Throws(RuntimeException::class)
    fun throwMsg(msg: String): Nothing {
        throw RuntimeException(msg)
    }

    @Throws(RuntimeException::class)
    fun throwIdNotFound(id: Any): Nothing {
        throwMsg("Failed to find asset $id")
    }
}
