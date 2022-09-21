package com.fluttercandies.photo_manager.core.utils

import android.content.Context
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.MediaStore.Files.FileColumns.*
import android.provider.MediaStore.VOLUME_EXTERNAL
import androidx.annotation.ChecksSdkIntAtLeast
import androidx.exifinterface.media.ExifInterface
import com.fluttercandies.photo_manager.core.PhotoManager
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.entity.DateCond
import com.fluttercandies.photo_manager.core.entity.FilterOption
import com.fluttercandies.photo_manager.core.entity.AssetPathEntity
import com.fluttercandies.photo_manager.util.LogUtils
import java.io.File

@Suppress("InlinedApi", "Range")
interface IDBUtils {
    companion object {
        @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.Q)
        val isAndroidQ = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

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
            MEDIA_TYPE,
            MediaStore.Images.Media.DISPLAY_NAME
        )

        val storeBucketKeys = arrayOf(
            MediaStore.MediaColumns.BUCKET_ID,
            MediaStore.MediaColumns.BUCKET_DISPLAY_NAME
        )

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
            MEDIA_TYPE_IMAGE -> 1
            MEDIA_TYPE_VIDEO -> 2
            MEDIA_TYPE_AUDIO -> 3
            else -> 0
        }
    }

    fun convertTypeToMediaType(type: Int): Int {
        return MediaStoreUtils.convertTypeToMediaType(type)
    }

    fun getTypeFromMediaType(mediaType: Int): Int {
        return when (mediaType) {
            MEDIA_TYPE_IMAGE -> 1
            MEDIA_TYPE_VIDEO -> 2
            MEDIA_TYPE_AUDIO -> 3
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
        val path = getString(MediaStore.MediaColumns.DATA)
        if (checkIfExists && path.isNotBlank() && !File(path).exists()) {
            return null
        }

        val id = getString(MediaStore.MediaColumns._ID)
        var date = if (isAndroidQ) getLong(MediaStore.MediaColumns.DATE_TAKEN)
        else getLong(MediaStore.MediaColumns.DATE_ADDED)
        if (date == 0L) {
            date = getLong(MediaStore.MediaColumns.DATE_ADDED)
        } else {
            date /= 1000
        }
        val type = getInt(MEDIA_TYPE)
        val mimeType = getString(MediaStore.MediaColumns.MIME_TYPE)
        val duration = if (type == MEDIA_TYPE_IMAGE) 0
        else getLong(MediaStore.MediaColumns.DURATION)
        var width = getInt(MediaStore.MediaColumns.WIDTH)
        var height = getInt(MediaStore.MediaColumns.HEIGHT)
        val displayName = getString(MediaStore.MediaColumns.DISPLAY_NAME)
        val modifiedDate = getLong(MediaStore.MediaColumns.DATE_MODIFIED)
        var orientation: Int = getInt(MediaStore.MediaColumns.ORIENTATION)
        val relativePath: String? = if (isAndroidQ) getString(MediaStore.MediaColumns.RELATIVE_PATH) else null
        if (width == 0 || height == 0) {
            try {
                if (type == MEDIA_TYPE_IMAGE && !mimeType.contains("svg")) {
                    val uri = getUri(id, getMediaType(type))
                    context.contentResolver.openInputStream(uri)?.use {
                        ExifInterface(it).apply {
                            width = getAttribute(ExifInterface.TAG_IMAGE_WIDTH)?.toInt() ?: width
                            height = getAttribute(ExifInterface.TAG_IMAGE_LENGTH)?.toInt() ?: height
                        }
                    }
                } else if (type == MEDIA_TYPE_VIDEO) {
                    MediaMetadataRetriever().use { mmr ->
                        mmr.setDataSource(path)
                        width = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 0
                        height = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 0
                        orientation =
                            mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toInt()
                                ?: orientation
                    }
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
        image: ByteArray,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity?

    fun saveImage(
        context: Context,
        path: String,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity?

    fun saveVideo(
        context: Context,
        path: String,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity?

    fun exists(context: Context, id: String): Boolean {
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
        val mediaType = MEDIA_TYPE
        var result = ""
        if (typeUtils.containsVideo(requestType)) {
            result = "OR ( $mediaType = $MEDIA_TYPE_VIDEO )"
        }
        if (typeUtils.containsAudio(requestType)) {
            result = "$result OR ( $mediaType = $MEDIA_TYPE_AUDIO )"
        }
        val size = "$WIDTH > 0 AND $HEIGHT > 0"
        val imageCondString = "( $mediaType = $MEDIA_TYPE_IMAGE AND $size )"
        result = "AND ($imageCondString $result)"
        return result
    }

    fun getCondFromType(type: Int, filterOption: FilterOption, args: ArrayList<String>): String {
        val cond = StringBuilder()
        val typeKey = MEDIA_TYPE

        val haveImage = RequestTypeUtils.containsImage(type)
        val haveVideo = RequestTypeUtils.containsVideo(type)
        val haveAudio = RequestTypeUtils.containsAudio(type)

        var imageCondString = ""
        var videoCondString = ""
        var audioCondString = ""

        if (haveImage) {
            val imageCond = filterOption.imageOption
            imageCondString = "$typeKey = ? "
            args.add(MEDIA_TYPE_IMAGE.toString())
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
            args.add(MEDIA_TYPE_VIDEO.toString())
            args.addAll(durationArgs)
        }

        if (haveAudio) {
            val audioCond = filterOption.audioOption
            val durationCond = audioCond.durationCond()
            val durationArgs = audioCond.durationArgs()
            audioCondString = "$typeKey = ? AND $durationCond"
            args.add(MEDIA_TYPE_AUDIO.toString())
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

    fun getMediaUri(context: Context, id: String, type: Int): String {
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

    fun getUri(id: String, type: Int, isOrigin: Boolean = false): Uri {
        var uri = when (type) {
            1 -> Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
            2 -> Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id)
            3 -> Uri.withAppendedPath(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
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

        val key = arrayOf(_ID, MEDIA_TYPE, DATA)
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
