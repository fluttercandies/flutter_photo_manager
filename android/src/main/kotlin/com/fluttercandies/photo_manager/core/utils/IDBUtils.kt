package com.fluttercandies.photo_manager.core.utils

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.MediaStore.MediaColumns.*
import android.provider.MediaStore.VOLUME_EXTERNAL
import androidx.annotation.ChecksSdkIntAtLeast
import androidx.exifinterface.media.ExifInterface
import com.fluttercandies.photo_manager.core.PhotoManager
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.entity.DateCond
import com.fluttercandies.photo_manager.core.entity.FilterOption
import com.fluttercandies.photo_manager.core.entity.AssetPathEntity
import com.fluttercandies.photo_manager.util.LogUtils
import java.io.*
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
        }

        val typeKeys = arrayOf(
            MediaStore.Files.FileColumns.MEDIA_TYPE,
            MediaStore.Images.Media.DISPLAY_NAME
        )

        val storeBucketKeys = arrayOf(BUCKET_ID, BUCKET_DISPLAY_NAME)

        val allUri: Uri
            get() = MediaStore.Files.getContentUri(VOLUME_EXTERNAL)
    }

    val idSelection: String
        get() = "${MediaStore.Images.Media._ID} = ?"

    val allUri: Uri
        get() = IDBUtils.allUri

    private val typeUtils: RequestTypeUtils
        get() = RequestTypeUtils

    fun getAssetPathList(
        context: Context,
        requestType: Int = 0,
        option: FilterOption
    ): List<AssetPathEntity>

    fun getAssetListPaged(
        context: Context,
        pathId: String,
        page: Int,
        size: Int,
        requestType: Int = 0,
        option: FilterOption,
    ): List<AssetEntity>

    fun getAssetListRange(
        context: Context,
        galleryId: String,
        start: Int,
        end: Int,
        requestType: Int,
        option: FilterOption
    ): List<AssetEntity>

    fun getAssetEntity(context: Context, id: String, checkIfExists: Boolean = true): AssetEntity?

    fun getMediaType(type: Int): Int {
        return when (type) {
            MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE -> 1
            MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO -> 2
            MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO -> 3
            else -> 0
        }
    }

    fun convertTypeToMediaType(type: Int): Int {
        return MediaStoreUtils.convertTypeToMediaType(type)
    }

    fun getTypeFromMediaType(mediaType: Int): Int {
        return when (mediaType) {
            MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE -> 1
            MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO -> 2
            MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO -> 3
            else -> 0
        }
    }

    fun Cursor.getInt(columnName: String): Int {
        return getInt(getColumnIndex(columnName))
    }

    fun Cursor.getString(columnName: String): String {
        return getString(getColumnIndex(columnName)) ?: ""
    }

    fun Cursor.getStringOrNull(columnName: String): String? {
        return getString(getColumnIndex(columnName))
    }

    fun Cursor.getLong(columnName: String): Long {
        return getLong(getColumnIndex(columnName))
    }

//    fun Cursor.getDouble(columnName: String): Double {
//        return getDouble(getColumnIndex(columnName))
//    }

    fun Cursor.toAssetEntity(context: Context, checkIfExists: Boolean = true): AssetEntity? {
        val path = getString(DATA)
        if (checkIfExists && path.isNotBlank() && !File(path).exists()) {
            return null
        }

        val id = getLong(_ID)
        var date = if (isAboveAndroidQ) {
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
        val relativePath: String? = if (isAboveAndroidQ) {
            getString(RELATIVE_PATH)
        } else null
        if (width == 0 || height == 0) {
            try {
                if (type == MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE && !mimeType.contains("svg")) {
                    val uri = getUri(id, getMediaType(type))
                    context.contentResolver.openInputStream(uri)?.use {
                        ExifInterface(it).apply {
                            width = getAttribute(ExifInterface.TAG_IMAGE_WIDTH)?.toInt() ?: width
                            height = getAttribute(ExifInterface.TAG_IMAGE_LENGTH)?.toInt() ?: height
                        }
                    }
                } else if (type == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) {
                    val mmr = MediaMetadataRetriever()
                    mmr.setDataSource(path)
                    width = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 0
                    height = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 0
                    orientation = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toInt()
                        ?: orientation
                    if (isAboveAndroidQ) mmr.close() else mmr.release()
                }
            } catch (e: Throwable) {
                LogUtils.error(e)
            }
        }
        return AssetEntity(
            id,
            path,
            duration,
            date,
            width,
            height,
            getMediaType(type),
            displayName,
            modifiedDate,
            orientation,
            androidQRelativePath = relativePath,
            mimeType = mimeType
        )
    }

    fun getAssetPathEntityFromId(
        context: Context,
        pathId: String,
        type: Int,
        option: FilterOption
    ): AssetPathEntity?

    fun getFilePath(context: Context, id: String, origin: Boolean): String?

    fun saveImage(
        context: Context,
        bytes: ByteArray,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity? {
        var inputStream = ByteArrayInputStream(bytes)
        fun refreshInputStream() {
            inputStream = ByteArrayInputStream(bytes)
        }

        val timestamp = System.currentTimeMillis() / 1000
        val (width, height) = try {
            val bmp = BitmapFactory.decodeStream(inputStream)
            Pair(bmp.width, bmp.height)
        } catch (e: Exception) {
            Pair(0, 0)
        }
        val typeFromStream: String = URLConnection.guessContentTypeFromName(title)
            ?: URLConnection.guessContentTypeFromStream(inputStream)
            ?: "image/*"
        val (rotationDegrees, latLong) = kotlin.run {
            try {
                val exif = ExifInterface(inputStream)
                Pair(
                    if (isAboveAndroidQ) exif.rotationDegrees else 0,
                    if (isAboveAndroidQ) null else exif.latLong
                )
            } catch (e: Exception) {
                Pair(0, null)
            }
        }
        refreshInputStream()

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
                put(DATE_TAKEN, timestamp * 1000)
                put(ORIENTATION, rotationDegrees)
                if (relativePath != null) {
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
        fromPath: String,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity? {
        fromPath.checkDirs()
        val file = File(fromPath)
        var inputStream = FileInputStream(file)
        fun refreshInputStream() {
            inputStream = FileInputStream(file)
        }

        val timestamp = System.currentTimeMillis() / 1000
        val (width, height) = try {
            val bmp = BitmapFactory.decodeStream(inputStream)
            Pair(bmp.width, bmp.height)
        } catch (e: Exception) {
            Pair(0, 0)
        }
        val typeFromStream: String = URLConnection.guessContentTypeFromName(title)
            ?: URLConnection.guessContentTypeFromName(fromPath)
            ?: URLConnection.guessContentTypeFromStream(inputStream)
            ?: "image/*"
        val (rotationDegrees, latLong) = try {
            val exif = ExifInterface(inputStream)
            Pair(
                if (isAboveAndroidQ) exif.rotationDegrees else 0,
                if (isAboveAndroidQ) null else exif.latLong
            )
        } catch (e: Exception) {
            Pair(0, null)
        }
        refreshInputStream()

        val shouldKeepPath = if (!isAboveAndroidQ) {
            val dir = Environment.getExternalStorageDirectory()
            file.absolutePath.startsWith(dir.path)
        } else false

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
                put(DATE_TAKEN, timestamp * 1000)
                put(ORIENTATION, rotationDegrees)
                if (relativePath != null) {
                    put(RELATIVE_PATH, relativePath)
                }
            }
            if (latLong != null) {
                put(MediaStore.Images.ImageColumns.LATITUDE, latLong.first())
                put(MediaStore.Images.ImageColumns.LONGITUDE, latLong.last())
            }
            if (shouldKeepPath) {
                put(DATA, fromPath)
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

    fun saveVideo(
        context: Context,
        fromPath: String,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity? {
        fromPath.checkDirs()
        val file = File(fromPath)
        var inputStream = FileInputStream(file)
        fun refreshInputStream() {
            inputStream = FileInputStream(file)
        }

        val timestamp = System.currentTimeMillis() / 1000
        val info = VideoUtils.getPropertiesUseMediaPlayer(fromPath)
        val typeFromStream = URLConnection.guessContentTypeFromName(title)
            ?: URLConnection.guessContentTypeFromName(fromPath)
            ?: "video/*"
        val (rotationDegrees, latLong) = try {
            val exif = ExifInterface(inputStream)
            Pair(
                if (isAboveAndroidQ) exif.rotationDegrees else 0,
                if (isAboveAndroidQ) null else exif.latLong
            )
        } catch (e: Exception) {
            Pair(0, null)
        }
        refreshInputStream()

        val shouldKeepPath = if (!isAboveAndroidQ) {
            val dir = Environment.getExternalStorageDirectory()
            file.absolutePath.startsWith(dir.path)
        } else false

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
                put(DATE_TAKEN, timestamp * 1000)
                put(ORIENTATION, rotationDegrees)
                if (relativePath != null) {
                    put(RELATIVE_PATH, relativePath)
                }
            }
            if (latLong != null) {
                put(MediaStore.Video.VideoColumns.LATITUDE, latLong.first())
                put(MediaStore.Video.VideoColumns.LONGITUDE, latLong.last())
            }
            if (shouldKeepPath) {
                put(DATA, fromPath)
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
    ): AssetEntity? {
        val cr = context.contentResolver
        val uri = cr.insert(contentUri, values) ?: throw RuntimeException("Cannot insert the new asset.")
        val id = ContentUris.parseId(uri)
        if (!shouldKeepPath) {
            val outputStream = cr.openOutputStream(uri)
                ?: throw RuntimeException("Cannot open the output stream for $uri.")
            outputStream.use { os -> inputStream.use { it.copyTo(os) } }
        }
        cr.notifyChange(uri, null)
        return getAssetEntity(context, id.toString())
    }

    fun assetExists(context: Context, id: String): Boolean {
        val columns = arrayOf(_ID)
        context.contentResolver.query(allUri, columns, "$_ID = ?", arrayOf(id), null).use {
            if (it == null) {
                return false
            }
            return it.count >= 1
        }
    }

    fun getExif(context: Context, id: String): ExifInterface?

    fun getOriginBytes(
        context: Context,
        asset: AssetEntity,
        needLocationPermission: Boolean
    ): ByteArray

    /**
     * Just filter [MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE]
     */
    fun sizeWhere(requestType: Int?, option: FilterOption): String {
        if (option.imageOption.sizeConstraint.ignoreSize) {
            return ""
        }
        if (requestType == null || !typeUtils.containsImage(requestType)) {
            return ""
        }
        val mediaType = MediaStore.Files.FileColumns.MEDIA_TYPE
        var result = ""
        if (typeUtils.containsVideo(requestType)) {
            result = "OR ( $mediaType = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO} )"
        }
        if (typeUtils.containsAudio(requestType)) {
            result = "$result OR ( $mediaType = ${MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO} )"
        }
        val size = "$WIDTH > 0 AND $HEIGHT > 0"
        val imageCondString = "( $mediaType = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} AND $size )"
        result = "AND ($imageCondString $result)"
        return result
    }

    fun getCondFromType(type: Int, filterOption: FilterOption, args: ArrayList<String>): String {
        val cond = StringBuilder()
        val typeKey = MediaStore.Files.FileColumns.MEDIA_TYPE

        val haveImage = RequestTypeUtils.containsImage(type)
        val haveVideo = RequestTypeUtils.containsVideo(type)
        val haveAudio = RequestTypeUtils.containsAudio(type)

        var imageCondString = ""
        var videoCondString = ""
        var audioCondString = ""

        if (haveImage) {
            val imageCond = filterOption.imageOption
            imageCondString = "$typeKey = ? "
            args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString())
            if (!imageCond.sizeConstraint.ignoreSize) {
                val sizeCond = imageCond.sizeCond()
                val sizeArgs = imageCond.sizeArgs()
                imageCondString = "$imageCondString AND $sizeCond"
                args.addAll(sizeArgs)
            }
        }

        if (haveVideo) {
            val videoCond = filterOption.videoOption
            val durationCond = videoCond.durationCond()
            val durationArgs = videoCond.durationArgs()
            videoCondString = "$typeKey = ? AND $durationCond"
            args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString())
            args.addAll(durationArgs)
        }

        if (haveAudio) {
            val audioCond = filterOption.audioOption
            val durationCond = audioCond.durationCond()
            val durationArgs = audioCond.durationArgs()
            audioCondString = "$typeKey = ? AND $durationCond"
            args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO.toString())
            args.addAll(durationArgs)
        }

        if (haveImage) {
            cond.append("( $imageCondString )")
        }

        if (haveVideo) {
            if (cond.isNotEmpty()) {
                cond.append("OR ")
            }
            cond.append("( $videoCondString )")
        }

        if (haveAudio) {
            if (cond.isNotEmpty()) {
                cond.append("OR ")
            }
            cond.append("( $audioCondString )")
        }

        return "AND ( $cond )"
    }

    fun logRowWithId(context: Context, id: String) {
        if (LogUtils.isLog) {
            val splitter = "".padStart(40, '-')
            LogUtils.info("log error row $id start $splitter")
            val cursor = context.contentResolver.query(allUri, null, "$_ID = ?", arrayOf(id), null)
            cursor?.use {
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

    fun getMediaUri(context: Context, id: Long, type: Int): String {
        val uri = getUri(id, type, false)
        return uri.toString()
    }

    fun getMainAssetPathEntity(
        context: Context,
        requestType: Int,
        option: FilterOption
    ): List<AssetPathEntity>

    fun getDateCond(args: ArrayList<String>, option: FilterOption): String {
        val createDateCond =
            addDateCond(args, option.createDateCond, MediaStore.Images.Media.DATE_ADDED)
        val updateDateCond =
            addDateCond(args, option.updateDateCond, MediaStore.Images.Media.DATE_MODIFIED)
        return "$createDateCond $updateDateCond"
    }

    private fun addDateCond(args: ArrayList<String>, dateCond: DateCond, dbKey: String): String {
        if (dateCond.ignore) {
            return ""
        }

        val minMs = dateCond.minMs
        val maxMs = dateCond.maxMs

        val dateSelection = "AND ( $dbKey >= ? AND $dbKey <= ? )"
        args.add((minMs / 1000).toString())
        args.add((maxMs / 1000).toString())

        return dateSelection
    }

    fun getSortOrder(start: Int, pageSize: Int, filterOption: FilterOption): String? {
        val orderBy = filterOption.orderByCondString()
        return "$orderBy LIMIT $pageSize OFFSET $start"
    }

    fun copyToGallery(context: Context, assetId: String, galleryId: String): AssetEntity?

    fun moveToGallery(context: Context, assetId: String, galleryId: String): AssetEntity?

    fun getSomeInfo(context: Context, assetId: String): Pair<String, String?>?

    fun getUri(id: Long, type: Int, isOrigin: Boolean = false): Uri {
        var uri = when (type) {
            1 -> ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
            2 -> ContentUris.withAppendedId(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id)
            3 -> ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
            else -> return Uri.EMPTY
        }

        if (isOrigin) {
            uri = MediaStore.setRequireOriginal(uri)
        }
        return uri
    }

    fun throwMsg(msg: String): Nothing {
        throw RuntimeException(msg)
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
        val cursor = context.contentResolver.query(
            allUri,
            key,
            selection,
            ids.toTypedArray(),
            null
        ) ?: return emptyList()
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

    fun getPathModifiedDate(context: Context, pathId: String): Long? {
        val columns = arrayOf(DATE_MODIFIED)
        val sortOrder = "$DATE_MODIFIED desc"
        val cursor = if (pathId == PhotoManager.ALL_ID) {
            context.contentResolver.query(allUri, columns, null, null, sortOrder)
        } else {
            context.contentResolver.query(
                allUri,
                columns,
                "$BUCKET_ID = ?",
                arrayOf(pathId),
                sortOrder
            )
        } ?: return null
        cursor.use {
            if (it.moveToNext()) {
                return it.getLong(DATE_MODIFIED)
            }
        }
        return null
    }
}
