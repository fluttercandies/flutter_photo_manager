package com.fluttercandies.photo_manager.core.utils

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.BaseColumns
import android.provider.MediaStore
import android.provider.MediaStore.Files.FileColumns.*
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.exifinterface.media.ExifInterface
import com.fluttercandies.photo_manager.core.PhotoManager
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.entity.FilterOption
import com.fluttercandies.photo_manager.core.entity.GalleryEntity
import com.fluttercandies.photo_manager.util.LogUtils
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.net.URLConnection
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

@RequiresApi(Build.VERSION_CODES.Q)
@Suppress("Deprecation") // Suppress DATA field
object AndroidQDBUtils : IDBUtils {
    private const val TAG = "PhotoManagerPlugin"

    private val galleryKeys = arrayOf(
        MediaStore.Images.Media.BUCKET_ID,
        MediaStore.Images.Media.BUCKET_DISPLAY_NAME
    )

    override fun getAssetPathList(
        context: Context,
        requestType: Int,
        option: FilterOption
    ): List<GalleryEntity> {
        val list = ArrayList<GalleryEntity>()
        val args = ArrayList<String>()
        val typeSelection: String = getCondFromType(requestType, option, args)
        val dateSelection = getDateCond(args, option)
        val sizeWhere = sizeWhere(requestType, option)
        val selections =
            "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"

        val cursor = context.contentResolver.query(
            allUri,
            galleryKeys,
            selections,
            args.toTypedArray(),
            option.orderByCondString()
        ) ?: return list
        val nameMap = HashMap<String, String>()
        val countMap = HashMap<String, Int>()
        cursor.use {
            LogUtils.logCursor(it, BUCKET_ID)
            while (it.moveToNext()) {
                val galleryId = it.getString(MediaStore.Images.Media.BUCKET_ID)
                if (nameMap.containsKey(galleryId)) {
                    countMap[galleryId] = countMap[galleryId]!! + 1
                    continue
                }
                val galleryName = it.getString(MediaStore.Images.Media.BUCKET_DISPLAY_NAME)
                nameMap[galleryId] = galleryName
                countMap[galleryId] = 1
            }
        }

        nameMap.forEach {
            val id = it.key
            val name = it.value
            val count = countMap[id]!!
            val entity = GalleryEntity(id, name, count, requestType, false)
            if (option.containsPathModified) {
                injectModifiedDate(context, entity)
            }
            list.add(entity)
        }
        return list
    }

    override fun getOnlyGalleryList(
        context: Context,
        requestType: Int,
        option: FilterOption
    ): List<GalleryEntity> {
        val list = ArrayList<GalleryEntity>()
        val args = ArrayList<String>()
        val typeSelection = getCondFromType(requestType, option, args)
        val dateSelection = getDateCond(args, option)
        val sizeWhere = sizeWhere(requestType, option)
        val selections =
            "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"

        val cursor = context.contentResolver.query(
            allUri,
            galleryKeys,
            selections,
            args.toTypedArray(),
            option.orderByCondString()
        ) ?: return list
        cursor.use {
            val count = cursor.count
            val galleryEntity = GalleryEntity(
                PhotoManager.ALL_ID,
                PhotoManager.ALL_ALBUM_NAME,
                count,
                requestType,
                true
            )
            list.add(galleryEntity)
        }
        return list
    }

    override fun getSortOrder(start: Int, pageSize: Int, filterOption: FilterOption): String? {
        if (isExternalStorageLegacy()) {
            return super.getSortOrder(start, pageSize, filterOption)
        }
        return filterOption.orderByCondString()
    }

    private fun cursorWithRange(
        cursor: Cursor,
        start: Int,
        pageSize: Int,
        block: (cursor: Cursor) -> Unit
    ) {
        if (!isExternalStorageLegacy()) {
            cursor.moveToPosition(start - 1)
        }
        for (i in 0 until pageSize) {
            if (cursor.moveToNext()) {
                block(cursor)
            }
        }
    }

    override fun getAssetListPaged(
        context: Context,
        galleryId: String,
        page: Int,
        size: Int,
        requestType: Int,
        option: FilterOption
    ): List<AssetEntity> {
        val isAll = galleryId.isEmpty()
        val list = ArrayList<AssetEntity>()
        val uri = allUri
        val args = ArrayList<String>()
        if (!isAll) {
            args.add(galleryId)
        }
        val typeSelection: String = getCondFromType(requestType, option, args)
        val sizeWhere = sizeWhere(requestType, option)
        val dateSelection = getDateCond(args, option)
        val keys = (assetKeys()).distinct().toTypedArray()
        val selection = if (isAll) {
            "${MediaStore.Images.ImageColumns.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"
        } else {
            "${MediaStore.Images.ImageColumns.BUCKET_ID} = ? $typeSelection $dateSelection $sizeWhere"
        }
        val sortOrder = getSortOrder(page * size, size, option)
        val cursor = context.contentResolver.query(
            uri,
            keys,
            selection,
            args.toTypedArray(),
            sortOrder
        ) ?: return emptyList()
        cursor.use {
            cursorWithRange(it, page * size, size) {
                val asset = convertCursorToAssetEntity(context, cursor)
                list.add(asset)
            }
        }
        return list
    }


    override fun getAssetListRange(
        context: Context,
        galleryId: String,
        start: Int,
        end: Int,
        requestType: Int,
        option: FilterOption
    ): List<AssetEntity> {
        val isAll = galleryId.isEmpty()
        val list = ArrayList<AssetEntity>()
        val uri = allUri
        val args = ArrayList<String>()
        if (!isAll) {
            args.add(galleryId)
        }
        val typeSelection: String = getCondFromType(requestType, option, args)
        val sizeWhere = sizeWhere(requestType, option)
        val dateSelection = getDateCond(args, option)
        val keys = assetKeys().distinct().toTypedArray()
        val selection = if (isAll) {
            "${MediaStore.Images.ImageColumns.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"
        } else {
            "${MediaStore.Images.ImageColumns.BUCKET_ID} = ? $typeSelection $dateSelection $sizeWhere"
        }
        val pageSize = end - start
        val sortOrder = getSortOrder(start, pageSize, option)
        val cursor = context.contentResolver.query(
            uri,
            keys,
            selection,
            args.toTypedArray(),
            sortOrder
        ) ?: return emptyList()
        cursor.use {
            cursorWithRange(it, start, pageSize) {
                list.add(convertCursorToAssetEntity(context, cursor))
            }
        }
        return list

    }

    private fun assetKeys() =
        IDBUtils.storeImageKeys + IDBUtils.storeVideoKeys + IDBUtils.typeKeys + arrayOf(MediaStore.MediaColumns.RELATIVE_PATH)

    private fun convertCursorToAssetEntity(context: Context, cursor: Cursor): AssetEntity {
        val id = cursor.getString(MediaStore.MediaColumns._ID)
        val path = cursor.getString(MediaStore.MediaColumns.DATA)
        var date = cursor.getLong(MediaStore.Images.Media.DATE_TAKEN)
        if (date == 0L) {
            date = cursor.getLong(MediaStore.Images.Media.DATE_ADDED)
        } else {
            date /= 1000
        }
        val type = cursor.getInt(MEDIA_TYPE)
        val mimeType = cursor.getString(MIME_TYPE)
        val duration = if (type == MEDIA_TYPE_IMAGE) 0
        else cursor.getLong(MediaStore.Video.VideoColumns.DURATION)
        var width = cursor.getInt(MediaStore.MediaColumns.WIDTH)
        var height = cursor.getInt(MediaStore.MediaColumns.HEIGHT)
        val displayName = cursor.getString(MediaStore.Images.Media.DISPLAY_NAME)
        val modifiedDate = cursor.getLong(MediaStore.MediaColumns.DATE_MODIFIED)
        val orientation: Int = cursor.getInt(MediaStore.MediaColumns.ORIENTATION)
        val relativePath: String = cursor.getString(MediaStore.MediaColumns.RELATIVE_PATH)
        if ((width == 0 || height == 0)
            && path.isNotBlank()
            && File(path).exists()
            && !mimeType.contains("svg")
        ) {
            try {
                val uri = getUri(id, getMediaType(type))
                context.contentResolver.openInputStream(uri)?.use {
                    ExifInterface(it).apply {
                        width = getAttribute(ExifInterface.TAG_IMAGE_WIDTH)?.toInt() ?: width
                        height = getAttribute(ExifInterface.TAG_IMAGE_LENGTH)?.toInt() ?: height
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

    override fun getAssetEntity(context: Context, id: String): AssetEntity? {
        val keys = assetKeys().distinct().toTypedArray()
        val selection = "$_ID = ?"
        val args = arrayOf(id)
        val cursor = context.contentResolver.query(
            allUri,
            keys,
            selection,
            args,
            null
        ) ?: return null
        cursor.use {
            return if (it.moveToNext()) convertCursorToAssetEntity(context, it)
            else null
        }
    }

    override fun getGalleryEntity(
        context: Context,
        galleryId: String,
        type: Int,
        option: FilterOption
    ): GalleryEntity? {
        val uri = allUri
        val projection = IDBUtils.storeBucketKeys
        val isAll = galleryId == ""
        val args = ArrayList<String>()
        val typeSelection: String = getCondFromType(type, option, args)
        val dateSelection = getDateCond(args, option)
        val idSelection: String
        if (isAll) {
            idSelection = ""
        } else {
            idSelection = "AND ${MediaStore.Images.Media.BUCKET_ID} = ?"
            args.add(galleryId)
        }
        val sizeWhere = sizeWhere(null, option)
        val selection =
            "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $idSelection $sizeWhere"
        val cursor = context.contentResolver.query(
            uri,
            projection,
            selection, args.toTypedArray(),
            null
        ) ?: return null
        val name: String
        val count: Int
        cursor.use {
            if (cursor.moveToNext()) {
                name = cursor.getString(1) ?: ""
                count = cursor.count
            } else {
                return null
            }
        }
        return GalleryEntity(galleryId, name, count, type, isAll)
    }

    override fun getExif(context: Context, id: String): ExifInterface? {
        return try {
            val asset = getAssetEntity(context, id) ?: return null
            val uri = getUri(asset)
            val originalUri = MediaStore.setRequireOriginal(uri)
            val inputStream = context.contentResolver.openInputStream(originalUri) ?: return null
            ExifInterface(inputStream)
        } catch (e: Exception) {
            null
        }
    }

    override fun getFilePath(context: Context, id: String, origin: Boolean): String? {
        val assetEntity = getAssetEntity(context, id) ?: return null
        return assetEntity.path
    }

    private fun getUri(asset: AssetEntity, isOrigin: Boolean = false): Uri =
        getUri(asset.id, asset.type, isOrigin)

    override fun getOriginBytes(
        context: Context,
        asset: AssetEntity,
        needLocationPermission: Boolean
    ): ByteArray {
        val uri = getUri(asset, needLocationPermission)
        val inputStream = context.contentResolver.openInputStream(uri)
        val outputStream = ByteArrayOutputStream()
        outputStream.use { os ->
            inputStream?.use { os.write(it.readBytes()) }
            val byteArray = outputStream.toByteArray()
            if (LogUtils.isLog) {
                LogUtils.info("The asset ${asset.id} origin byte length : ${byteArray.count()}")
            }
            return byteArray
        }
    }

    override fun saveImage(
        context: Context,
        image: ByteArray,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity? {
        val (width, height) = try {
            val bmp = BitmapFactory.decodeByteArray(image, 0, image.count())
            Pair(bmp.width, bmp.height)
        } catch (e: Exception) {
            Pair(0, 0)
        }
        var inputStream = ByteArrayInputStream(image)
        fun refreshInputStream() {
            inputStream = ByteArrayInputStream(image)
        }

        val rotationDegrees = inputStream.getOrientationDegrees()
        refreshInputStream()

        val typeFromStream: String = if (title.contains(".")) {
            // Title contains file extension.
            "image/${File(title).extension}"
        } else {
            URLConnection.guessContentTypeFromStream(inputStream) ?: "image/*"
        }

        val timestamp = System.currentTimeMillis() / 1000
        val values = ContentValues().apply {
            put(MEDIA_TYPE, MEDIA_TYPE_IMAGE)
            put(MediaStore.MediaColumns.DISPLAY_NAME, title)
            put(MediaStore.Images.ImageColumns.MIME_TYPE, typeFromStream)
            put(MediaStore.Images.ImageColumns.TITLE, title)
            put(MediaStore.Images.ImageColumns.DESCRIPTION, desc)
            put(MediaStore.Images.ImageColumns.DATE_ADDED, timestamp)
            put(MediaStore.Images.ImageColumns.DATE_MODIFIED, timestamp)
            put(MediaStore.Images.ImageColumns.DATE_TAKEN, timestamp * 1000)
            put(MediaStore.Images.ImageColumns.WIDTH, width)
            put(MediaStore.Images.ImageColumns.HEIGHT, height)
            put(MediaStore.Images.ImageColumns.ORIENTATION, rotationDegrees)
            if (relativePath != null) {
                put(MediaStore.Images.ImageColumns.RELATIVE_PATH, relativePath)
            }
        }

        val cr = context.contentResolver
        val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val contentUri = cr.insert(uri, values) ?: return null
        val outputStream = cr.openOutputStream(contentUri)
        outputStream?.use { os -> inputStream.use { it.copyTo(os) } }
        cr.notifyChange(contentUri, null)

        val id = ContentUris.parseId(contentUri)
        return getAssetEntity(context, id.toString())
    }

    override fun saveImage(
        context: Context,
        path: String,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity? {
        path.checkDirs()
        val cr = context.contentResolver
        val timestamp = System.currentTimeMillis() / 1000
        var inputStream = FileInputStream(path)
        fun refreshInputStream() {
            inputStream = FileInputStream(path)
        }

        val (width, height) = try {
            val bmp = BitmapFactory.decodeFile(path)
            Pair(bmp.width, bmp.height)
        } catch (e: Exception) {
            Pair(0, 0)
        }
        val rotationDegrees = inputStream.getOrientationDegrees()
        refreshInputStream()
        val typeFromStream = URLConnection.guessContentTypeFromStream(inputStream)
            ?: "image/${File(path).extension}"
        val values = ContentValues().apply {
            put(MEDIA_TYPE, MEDIA_TYPE_IMAGE)
            put(MediaStore.MediaColumns.DISPLAY_NAME, title)
            put(MediaStore.Images.ImageColumns.MIME_TYPE, typeFromStream)
            put(MediaStore.Images.ImageColumns.TITLE, title)
            put(MediaStore.Images.ImageColumns.DESCRIPTION, desc)
            put(MediaStore.Images.ImageColumns.DATE_ADDED, timestamp)
            put(MediaStore.Images.ImageColumns.DATE_MODIFIED, timestamp)
            put(MediaStore.Images.ImageColumns.DATE_TAKEN, timestamp * 1000)
            put(MediaStore.Images.ImageColumns.DISPLAY_NAME, title)
            put(MediaStore.Images.ImageColumns.DURATION, 0)
            put(MediaStore.Images.ImageColumns.WIDTH, width)
            put(MediaStore.Images.ImageColumns.HEIGHT, height)
            put(MediaStore.Images.ImageColumns.ORIENTATION, rotationDegrees)
            if (relativePath != null) {
                put(MediaStore.Images.ImageColumns.RELATIVE_PATH, relativePath)
            }
        }

        val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val contentUri = cr.insert(uri, values) ?: return null
        val outputStream = cr.openOutputStream(contentUri)
        outputStream?.use { os -> inputStream.use { it.copyTo(os) } }
        cr.notifyChange(contentUri, null)

        val id = ContentUris.parseId(contentUri)
        return getAssetEntity(context, id.toString())
    }

    override fun copyToGallery(context: Context, assetId: String, galleryId: String): AssetEntity? {
        val (currentGalleryId, _) = getSomeInfo(context, assetId)
            ?: throwMsg("Cannot get gallery id of $assetId")
        if (galleryId == currentGalleryId) {
            throwMsg("No copy required, because the target gallery is the same as the current one.")
        }
        val asset = getAssetEntity(context, assetId)
            ?: throwMsg("No copy required, because the target gallery is the same as the current one.")

        val copyKeys = arrayListOf(
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.Video.VideoColumns.TITLE,
            MediaStore.Video.VideoColumns.DATE_ADDED,
            MediaStore.Video.VideoColumns.DATE_MODIFIED,
            MediaStore.Video.VideoColumns.DATE_TAKEN,
            MediaStore.Video.VideoColumns.DURATION,
            MediaStore.Video.VideoColumns.WIDTH,
            MediaStore.Video.VideoColumns.HEIGHT,
            MediaStore.Video.VideoColumns.ORIENTATION
        )

        val mediaType = convertTypeToMediaType(asset.type)
        if (mediaType == MEDIA_TYPE_VIDEO) {
            copyKeys.add(MediaStore.Video.VideoColumns.DESCRIPTION)
        }

        val cr = context.contentResolver
        val cursor = cr.query(
            allUri,
            copyKeys.toTypedArray() + arrayOf(MediaStore.Video.VideoColumns.RELATIVE_PATH),
            idSelection,
            arrayOf(assetId),
            null
        ) ?: throwMsg("Cannot find asset.")
        if (!cursor.moveToNext()) {
            throwMsg("Cannot find asset.")
        }

        val insertUri = MediaStoreUtils.getInsertUri(mediaType)
        val relativePath = getRelativePath(context, galleryId)
        val cv = ContentValues().apply {
            for (key in copyKeys) {
                put(key, cursor.getString(key))
            }
            put(MEDIA_TYPE, mediaType)
            put(RELATIVE_PATH, relativePath)
        }

        val insertedUri = cr.insert(insertUri, cv) ?: throwMsg("Cannot insert new asset.")
        val outputStream = cr.openOutputStream(insertedUri)
            ?: throwMsg("Cannot open output stream for $insertedUri.")
        val inputUri = getUri(asset, true)
        val inputStream = cr.openInputStream(inputUri)
            ?: throwMsg("Cannot open input stream for $inputUri")
        inputStream.use {
            outputStream.use {
                inputStream.copyTo(outputStream)
            }
        }
        cursor.close()

        val insertedId = insertedUri.lastPathSegment
            ?: throwMsg("Cannot open output stream for $insertedUri.")
        return getAssetEntity(context, insertedId)
    }

    override fun moveToGallery(context: Context, assetId: String, galleryId: String): AssetEntity? {
        val (currentGalleryId, _) = getSomeInfo(context, assetId)
            ?: throwMsg("Cannot get gallery id of $assetId")

        if (galleryId == currentGalleryId) {
            throwMsg("No move required, because the target gallery is the same as the current one.")
        }

        val cr = context.contentResolver
        val targetPath = getRelativePath(context, galleryId)
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.RELATIVE_PATH, targetPath)
        }
        val count = cr.update(allUri, contentValues, idSelection, arrayOf(assetId))
        if (count > 0) {
            return getAssetEntity(context, assetId)
        }
        throwMsg("Cannot update $assetId relativePath")
    }

    private val deleteLock = ReentrantLock()

    override fun removeAllExistsAssets(context: Context): Boolean {
        if (deleteLock.isLocked) {
            Log.i(TAG, "The removeAllExistsAssets is running.")
            return false
        }
        deleteLock.withLock {
            Log.i(TAG, "The removeAllExistsAssets is starting.")
            val removedList = ArrayList<String>()
            val cr = context.contentResolver
            val cursor = cr.query(
                allUri,
                arrayOf(BaseColumns._ID, MEDIA_TYPE, DATA),
                "$MEDIA_TYPE in ( ?,?,? )",
                arrayOf(MEDIA_TYPE_AUDIO, MEDIA_TYPE_VIDEO, MEDIA_TYPE_IMAGE).map { it.toString() }
                    .toTypedArray(),
                null
            ) ?: return false
            cursor.use {
                var count = 0
                while (it.moveToNext()) {
                    val id = it.getString(BaseColumns._ID)
                    val mediaType = it.getInt(MEDIA_TYPE)
                    val path = it.getStringOrNull(DATA)
                    val type = getTypeFromMediaType(mediaType)
                    val uri = getUri(id, type)
                    val exists = try {
                        cr.openInputStream(uri)?.close()
                        true
                    } catch (e: Exception) {
                        false
                    }
                    if (!exists) {
                        removedList.add(id)
                        Log.i(TAG, "The $id, $path media was not exists. ")
                    }
                    count++
                    if (count % 300 == 0) {
                        Log.i(TAG, "Current checked count == $count")
                    }
                }
                Log.i(
                    TAG,
                    "The removeAllExistsAssets was stopped, will be delete ids = $removedList"
                )
            }
            val idWhere = removedList.joinToString(",") { "?" }
            // Remove exists rows.
            val deleteRowCount = cr.delete(
                allUri,
                "${BaseColumns._ID} in ( $idWhere )",
                removedList.toTypedArray()
            )
            Log.i("PhotoManagerPlugin", "Delete rows: $deleteRowCount")
        }
        return true
    }

    private fun getRelativePath(context: Context, galleryId: String): String? {
        val cr = context.contentResolver
        val cursor = cr.query(
            allUri,
            arrayOf(BUCKET_ID, RELATIVE_PATH),
            "$BUCKET_ID = ?",
            arrayOf(galleryId),
            null
        ) ?: return null
        cursor.use {
            if (!cursor.moveToNext()) {
                return null
            }
            return cursor.getString(1)
        }
    }

    override fun getSomeInfo(context: Context, assetId: String): Pair<String, String?>? {
        val cr = context.contentResolver
        val cursor = cr.query(
            allUri,
            arrayOf(BUCKET_ID, RELATIVE_PATH),
            "$_ID = ?",
            arrayOf(assetId),
            null
        ) ?: return null
        cursor.use {
            if (!cursor.moveToNext()) {
                return null
            }
            val galleryID = cursor.getString(0)
            val path = cursor.getString(1)
            return Pair(galleryID, File(path).parent)
        }
    }

    override fun saveVideo(
        context: Context,
        path: String,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity? {
        path.checkDirs()
        val cr = context.contentResolver
        val timestamp = System.currentTimeMillis() / 1000
        var inputStream = FileInputStream(path)
        fun refreshInputStream() {
            inputStream = FileInputStream(path)
        }

        val rotationDegrees = inputStream.getOrientationDegrees()
        refreshInputStream()

        val typeFromStream = URLConnection.guessContentTypeFromStream(inputStream)
            ?: "video/${File(path).extension}"
        val uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val info = VideoUtils.getPropertiesUseMediaPlayer(path)
        val values = ContentValues().apply {
            put(MEDIA_TYPE, MEDIA_TYPE_VIDEO)
            put(MediaStore.MediaColumns.DISPLAY_NAME, title)
            put(MediaStore.Video.VideoColumns.MIME_TYPE, typeFromStream)
            put(MediaStore.Video.VideoColumns.TITLE, title)
            put(MediaStore.Video.VideoColumns.DESCRIPTION, desc)
            put(MediaStore.Video.VideoColumns.DATE_ADDED, timestamp)
            put(MediaStore.Video.VideoColumns.DATE_MODIFIED, timestamp)
            put(MediaStore.Video.VideoColumns.DATE_TAKEN, timestamp * 1000)
            put(MediaStore.Video.VideoColumns.DISPLAY_NAME, title)
            put(MediaStore.Video.VideoColumns.DURATION, info.duration)
            put(MediaStore.Video.VideoColumns.WIDTH, info.width)
            put(MediaStore.Video.VideoColumns.HEIGHT, info.height)
            put(MediaStore.Video.VideoColumns.ORIENTATION, rotationDegrees)
            if (relativePath != null) {
                put(MediaStore.Video.VideoColumns.RELATIVE_PATH, relativePath)
            }
        }

        val contentUri = cr.insert(uri, values) ?: return null
        val outputStream = cr.openOutputStream(contentUri)
        outputStream?.use { os -> inputStream.use { it.copyTo(os) } }
        cr.notifyChange(contentUri, null)

        val id = ContentUris.parseId(contentUri)
        return getAssetEntity(context, id.toString())
    }
}
