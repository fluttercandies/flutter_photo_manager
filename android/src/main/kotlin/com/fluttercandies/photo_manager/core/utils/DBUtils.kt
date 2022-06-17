package com.fluttercandies.photo_manager.core.utils

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.graphics.BitmapFactory
import android.os.Environment
import android.provider.BaseColumns._ID
import android.provider.MediaStore
import android.util.Log
import androidx.exifinterface.media.ExifInterface
import com.fluttercandies.photo_manager.core.PhotoManager
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.entity.FilterOption
import com.fluttercandies.photo_manager.core.entity.GalleryEntity
import com.fluttercandies.photo_manager.core.utils.IDBUtils.Companion.storeBucketKeys
import com.fluttercandies.photo_manager.core.utils.IDBUtils.Companion.storeImageKeys
import com.fluttercandies.photo_manager.core.utils.IDBUtils.Companion.storeVideoKeys
import com.fluttercandies.photo_manager.core.utils.IDBUtils.Companion.typeKeys
import com.fluttercandies.photo_manager.util.LogUtils
import java.io.*
import java.net.URLConnection
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

/// Call the MediaStore API and get entity for the data.
@Suppress("Deprecation", "InlinedApi")
object DBUtils : IDBUtils {
    private val locationKeys = arrayOf(
        MediaStore.Images.ImageColumns.LONGITUDE,
        MediaStore.Images.ImageColumns.LATITUDE
    )

    override fun getAssetPathList(
        context: Context,
        requestType: Int,
        option: FilterOption
    ): List<GalleryEntity> {
        val list = ArrayList<GalleryEntity>()
        val uri = allUri
        val projection = storeBucketKeys + arrayOf("count(1)")
        val args = ArrayList<String>()
        val typeSelection: String = getCondFromType(requestType, option, args)
        val dateSelection = getDateCond(args, option)
        val sizeWhere = sizeWhere(requestType, option)
        val selection =
            "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere) GROUP BY (${MediaStore.Images.Media.BUCKET_ID}"
        val cursor = context.contentResolver.query(
            uri,
            projection,
            selection,
            args.toTypedArray(),
            null
        ) ?: return emptyList()
        cursor.use {
            while (it.moveToNext()) {
                val id = it.getString(0)
                val name = it.getString(1) ?: ""
                val count = it.getInt(2)
                val entity = GalleryEntity(id, name, count, 0)
                if (option.containsPathModified) {
                    injectModifiedDate(context, entity)
                }
                list.add(entity)
            }
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
        val typeSelection: String = getCondFromType(requestType, option, args)
        val projection = storeBucketKeys + arrayOf("count(1)")
        val dateSelection = getDateCond(args, option)
        val sizeWhere = sizeWhere(requestType, option)
        val selections =
            "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"

        val cursor = context.contentResolver.query(
            allUri,
            projection,
            selections,
            args.toTypedArray(),
            null
        ) ?: return list
        cursor.use {
            if (it.moveToNext()) {
                val countIndex = projection.indexOf("count(1)")
                val count = cursor.getInt(countIndex)
                val galleryEntity = GalleryEntity(
                    PhotoManager.ALL_ID,
                    PhotoManager.ALL_ALBUM_NAME,
                    count,
                    requestType,
                    true
                )
                list.add(galleryEntity)
            }
        }
        return list
    }

    override fun getGalleryEntity(
        context: Context,
        galleryId: String,
        type: Int,
        option: FilterOption
    ): GalleryEntity? {
        val uri = allUri
        val projection = storeBucketKeys + arrayOf("count(1)")
        val args = ArrayList<String>()
        val typeSelection: String = getCondFromType(type, option, args)
        val dateSelection = getDateCond(args, option)
        val idSelection: String
        if (galleryId == "") {
            idSelection = ""
        } else {
            idSelection = "AND ${MediaStore.Images.Media.BUCKET_ID} = ?"
            args.add(galleryId)
        }
        val sizeWhere = sizeWhere(null, option)
        val selection =
            "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $idSelection $sizeWhere) GROUP BY (${MediaStore.Images.Media.BUCKET_ID}"
        val cursor = context.contentResolver.query(
            uri,
            projection,
            selection,
            args.toTypedArray(),
            null
        ) ?: return null
        cursor.use {
            return if (it.moveToNext()) {
                val id = it.getString(0)
                val name = it.getString(1) ?: ""
                val count = it.getInt(2)
                GalleryEntity(id, name, count, 0)
            } else {
                null
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
        val typeSelection = getCondFromType(requestType, option, args)
        val dateSelection = getDateCond(args, option)
        val sizeWhere = sizeWhere(requestType, option)
        val keys =
            (storeImageKeys + storeVideoKeys + typeKeys + locationKeys).distinct().toTypedArray()
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
            while (it.moveToNext()) {
                list.add(convertCursorToAsset(context, it, requestType))
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
        val typeSelection = getCondFromType(requestType, option, args)
        val dateSelection = getDateCond(args, option)
        val sizeWhere = sizeWhere(requestType, option)
        val keys =
            (storeImageKeys + storeVideoKeys + typeKeys + locationKeys).distinct().toTypedArray()
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
            while (cursor.moveToNext()) {
                list.add(convertCursorToAsset(context, cursor, requestType))
            }
        }
        return list
    }

    private fun convertCursorToAsset(context: Context, cursor: Cursor, requestType: Int): AssetEntity {
        val id = cursor.getString(MediaStore.MediaColumns._ID)
        val path = cursor.getString(MediaStore.MediaColumns.DATA)
        val date = cursor.getLong(MediaStore.Images.Media.DATE_ADDED)
        val type = cursor.getInt(MediaStore.Files.FileColumns.MEDIA_TYPE)
        val duration = if (requestType == 1) 0
        else cursor.getLong(MediaStore.Video.VideoColumns.DURATION)
        var width = cursor.getInt(MediaStore.MediaColumns.WIDTH)
        var height = cursor.getInt(MediaStore.MediaColumns.HEIGHT)
        val displayName = File(path).name
        val modifiedDate = cursor.getLong(MediaStore.MediaColumns.DATE_MODIFIED)
        val lat = cursor.getDouble(MediaStore.Images.ImageColumns.LATITUDE)
        val lng = cursor.getDouble(MediaStore.Images.ImageColumns.LONGITUDE)
        val orientation: Int = cursor.getInt(MediaStore.Images.ImageColumns.ORIENTATION)
        val mimeType = cursor.getString(MediaStore.Files.FileColumns.MIME_TYPE)
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
            lat,
            lng,
            mimeType = mimeType
        )
    }

    override fun getAssetEntity(context: Context, id: String): AssetEntity? {
        val keys =
            (storeImageKeys + storeVideoKeys + locationKeys + typeKeys).distinct().toTypedArray()
        val selection = "${MediaStore.Files.FileColumns._ID} = ?"
        val args = arrayOf(id)

        val cursor = context.contentResolver.query(
            allUri,
            keys,
            selection,
            args,
            null
        ) ?: return null
        cursor.use {
            return if (it.moveToNext()) {
                val type = it.getInt(MediaStore.Files.FileColumns.MEDIA_TYPE)
                convertCursorToAsset(context, it, type)
            } else {
                null
            }
        }
    }

    override fun getOriginBytes(
        context: Context,
        asset: AssetEntity,
        needLocationPermission: Boolean
    ): ByteArray {
        return File(asset.path).readBytes()
    }

    override fun getExif(context: Context, id: String): ExifInterface? {
        val asset = getAssetEntity(context, id) ?: return null
        val file = File(asset.path)
        return if (file.exists()) ExifInterface(asset.path) else null
    }

    override fun getFilePath(context: Context, id: String, origin: Boolean): String? {
        val assetEntity = getAssetEntity(context, id) ?: return null
        return assetEntity.path
    }

    override fun saveImage(
        context: Context,
        image: ByteArray,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity? {
        val cr = context.contentResolver
        var inputStream = ByteArrayInputStream(image)
        fun refreshInputStream() {
            inputStream = ByteArrayInputStream(image)
        }

        val latLong = kotlin.run {
            val exifInterface = try {
                ExifInterface(inputStream)
            } catch (e: Exception) {
                return@run doubleArrayOf(0.0, 0.0)
            }
            exifInterface.latLong ?: doubleArrayOf(0.0, 0.0)
        }
        refreshInputStream()

        val bmp = BitmapFactory.decodeStream(inputStream)
        val width = bmp.width
        val height = bmp.height
        val timestamp = System.currentTimeMillis() / 1000
        refreshInputStream()

        val typeFromStream: String = if (title.contains(".")) {
            // title contains file extension, form mimeType from it
            "image/${File(title).extension}"
        } else {
            URLConnection.guessContentTypeFromStream(inputStream) ?: "image/*"
        }

        val values = ContentValues().apply {
            put(
                MediaStore.Files.FileColumns.MEDIA_TYPE,
                MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
            )
            put(MediaStore.MediaColumns.DISPLAY_NAME, title)
            put(MediaStore.Images.ImageColumns.MIME_TYPE, typeFromStream)
            put(MediaStore.Images.ImageColumns.TITLE, title)
            put(MediaStore.Images.ImageColumns.DESCRIPTION, desc)
            put(MediaStore.Images.ImageColumns.DATE_ADDED, timestamp)
            put(MediaStore.Images.ImageColumns.DATE_MODIFIED, timestamp)
            put(MediaStore.Images.ImageColumns.DISPLAY_NAME, title)
            put(MediaStore.Images.ImageColumns.WIDTH, width)
            put(MediaStore.Images.ImageColumns.HEIGHT, height)
            put(MediaStore.Images.ImageColumns.LATITUDE, latLong[0])
            put(MediaStore.Images.ImageColumns.LONGITUDE, latLong[1])
        }

        val insertUri = cr.insert(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            values
        ) ?: return null

        // Write bytes.
        val cursor = cr.query(
            insertUri,
            arrayOf(MediaStore.Images.ImageColumns.DATA),
            null,
            null,
            null
        ) ?: return null
        cursor.use {
            if (it.moveToNext()) {
                val targetPath = it.getString(0)
                targetPath.checkDirs()
                val outputStream = FileOutputStream(targetPath)
                refreshInputStream()
                outputStream.use { os -> inputStream.use { inputStream.copyTo(os) } }
            }
        }
        val id = ContentUris.parseId(insertUri)
        return getAssetEntity(context, id.toString())
    }

    override fun saveImage(
        context: Context,
        path: String,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity? {
        val cr = context.contentResolver
        val file = File(path)
        var inputStream = FileInputStream(file)
        fun refreshInputStream() {
            inputStream = FileInputStream(file)
        }

        val latLong = kotlin.run {
            val exifInterface = try {
                ExifInterface(inputStream)
            } catch (e: Exception) {
                return@run doubleArrayOf(0.0, 0.0)
            }
            exifInterface.latLong ?: doubleArrayOf(0.0, 0.0)
        }
        refreshInputStream()

        val (width, height) = try {
            val bmp = BitmapFactory.decodeFile(path)
            Pair(bmp.width, bmp.height)
        } catch (e: Exception) {
            Pair(0, 0)
        }
        val timestamp = System.currentTimeMillis() / 1000

        val typeFromStream = URLConnection.guessContentTypeFromStream(inputStream)
            ?: "image/${File(path).extension}"
        refreshInputStream()

        val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val dir = Environment.getExternalStorageDirectory()
        val savePath = file.absolutePath.startsWith(dir.path)
        val values = ContentValues().apply {
            put(
                MediaStore.Files.FileColumns.MEDIA_TYPE,
                MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
            )
            put(MediaStore.MediaColumns.DISPLAY_NAME, title)
            put(MediaStore.Images.ImageColumns.MIME_TYPE, typeFromStream)
            put(MediaStore.Images.ImageColumns.TITLE, title)
            put(MediaStore.Images.ImageColumns.DESCRIPTION, desc)
            put(MediaStore.Images.ImageColumns.DATE_ADDED, timestamp)
            put(MediaStore.Images.ImageColumns.DATE_MODIFIED, timestamp)
            put(MediaStore.Images.ImageColumns.DISPLAY_NAME, title)
            put(MediaStore.Images.ImageColumns.LATITUDE, latLong[0])
            put(MediaStore.Images.ImageColumns.LONGITUDE, latLong[1])
            put(MediaStore.Images.ImageColumns.WIDTH, width)
            put(MediaStore.Images.ImageColumns.HEIGHT, height)
            if (savePath) {
                put(MediaStore.Video.VideoColumns.DATA, path)
            }
        }

        val contentUri = cr.insert(uri, values) ?: return null
        val id = ContentUris.parseId(contentUri)
        val assetEntity = getAssetEntity(context, id.toString())
        if (!savePath) {
            val tmpPath = assetEntity?.path!!
            tmpPath.checkDirs()
            val tmpFile = File(tmpPath)
            val targetPath = "${tmpFile.parent}/$title"
            val targetFile = File(targetPath)
            if (targetFile.exists()) {
                throw IOException("save target path is ")
            }
            tmpFile.renameTo(targetFile)
            val updateDataValues = ContentValues().apply {
                put(MediaStore.Video.VideoColumns.DATA, targetPath)
            }
            cr.update(contentUri, updateDataValues, null, null)
            val outputStream = FileOutputStream(targetFile)
            outputStream.use { os -> inputStream.use { it.copyTo(os) } }
            assetEntity.path = targetPath
        }
        cr.notifyChange(contentUri, null)
        return assetEntity
    }

    override fun copyToGallery(context: Context, assetId: String, galleryId: String): AssetEntity? {
        val (currentGalleryId, _) = getSomeInfo(context, assetId)
            ?: throw RuntimeException("Cannot get gallery id of $assetId")
        if (galleryId == currentGalleryId) {
            throw RuntimeException("No copy required, because the target gallery is the same as the current one.")
        }
        val cr = context.contentResolver
        val asset = getAssetEntity(context, assetId)
            ?: throw RuntimeException("No copy required, because the target gallery is the same as the current one.")

        val copyKeys = arrayListOf(
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.Video.VideoColumns.TITLE,
            MediaStore.Video.VideoColumns.DATE_ADDED,
            MediaStore.Video.VideoColumns.DATE_MODIFIED,
            MediaStore.Video.VideoColumns.DATE_TAKEN,
            MediaStore.Video.VideoColumns.DURATION,
            MediaStore.Video.VideoColumns.LONGITUDE,
            MediaStore.Video.VideoColumns.LATITUDE,
            MediaStore.Video.VideoColumns.WIDTH,
            MediaStore.Video.VideoColumns.HEIGHT
        )
        val mediaType = convertTypeToMediaType(asset.type)
        if (mediaType != MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO) {
            copyKeys.add(MediaStore.Video.VideoColumns.DESCRIPTION)
        }

        val cursor = cr.query(
            allUri,
            copyKeys.toTypedArray() + arrayOf(MediaStore.Video.VideoColumns.DATA),
            idSelection,
            arrayOf(assetId),
            null
        ) ?: throw RuntimeException("Cannot find asset .")
        if (!cursor.moveToNext()) {
            throw RuntimeException("Cannot find asset .")
        }
        val insertUri = MediaStoreUtils.getInsertUri(mediaType)
        val galleryInfo = getGalleryInfo(context, galleryId) ?: throwMsg("Cannot find gallery info")
        val outputPath = "${galleryInfo.path}/${asset.displayName}"
        val cv = ContentValues().apply {
            for (key in copyKeys) {
                put(key, cursor.getString(key))
            }
            put(MediaStore.Files.FileColumns.MEDIA_TYPE, mediaType)
            put(MediaStore.Files.FileColumns.DATA, outputPath)
        }

        val insertedUri =
            cr.insert(insertUri, cv) ?: throw RuntimeException("Cannot insert new asset.")
        val outputStream = cr.openOutputStream(insertedUri)
            ?: throw RuntimeException("Cannot open output stream for $insertedUri.")
        val inputStream = File(asset.path).inputStream()
        inputStream.use {
            outputStream.use {
                inputStream.copyTo(outputStream)
            }
        }

        cursor.close()
        val insertedId = insertedUri.lastPathSegment
            ?: throw RuntimeException("Cannot open output stream for $insertedUri.")
        return getAssetEntity(context, insertedId)
    }

    override fun moveToGallery(context: Context, assetId: String, galleryId: String): AssetEntity? {
        val (currentGalleryId, _) = getSomeInfo(context, assetId)
            ?: throwMsg("Cannot get gallery id of $assetId")

        val targetGalleryInfo = getGalleryInfo(context, galleryId)
            ?: throwMsg("Cannot get target gallery info")

        if (galleryId == currentGalleryId) {
            throwMsg("No move required, because the target gallery is the same as the current one.")
        }

        val cr = context.contentResolver
        val cursor = cr.query(
            allUri,
            arrayOf(MediaStore.MediaColumns.DATA),
            idSelection,
            arrayOf(assetId),
            null
        ) ?: throwMsg("Cannot find $assetId path")

        val targetPath = if (cursor.moveToNext()) {
            val srcPath = cursor.getString(0)
            cursor.close()
            val target = "${targetGalleryInfo.path}/${File(srcPath).name}"
            File(srcPath).renameTo(File(target))
            target
        } else {
            throwMsg("Cannot find $assetId path")
        }

        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DATA, targetPath)
            put(MediaStore.Files.FileColumns.BUCKET_ID, galleryId)
            put(MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME, targetGalleryInfo.galleryName)
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
            return false
        }
        deleteLock.withLock {
            val removedList = ArrayList<String>()
            val cr = context.contentResolver
            val cursor = cr.query(
                allUri,
                arrayOf(_ID, MediaStore.MediaColumns.DATA),
                null,
                null,
                null
            ) ?: return false
            cursor.use {
                while (it.moveToNext()) {
                    val id = it.getString(_ID)
                    val path = it.getString(MediaStore.MediaColumns.DATA)
                    if (!File(path).exists()) {
                        removedList.add(id)
                        Log.i("PhotoManagerPlugin", "The $path was not exists. ")
                    }
                }
                Log.i("PhotoManagerPlugin", "will be delete ids = $removedList")
            }
            val idWhere = removedList.joinToString(",") { "?" }
            // Remove exists rows.
            val deleteRowCount = cr.delete(
                allUri,
                "$_ID in ( $idWhere )",
                removedList.toTypedArray()
            )
            Log.i("PhotoManagerPlugin", "Delete rows: $deleteRowCount")
        }
        return true
    }

    /**
     * 0 : gallery id
     * 1 : current asset parent path
     */
    override fun getSomeInfo(context: Context, assetId: String): Pair<String, String?>? {
        val cursor = context.contentResolver.query(
            allUri,
            arrayOf(MediaStore.Files.FileColumns.BUCKET_ID, MediaStore.Files.FileColumns.DATA),
            "${MediaStore.Files.FileColumns._ID} = ?",
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

    private fun getGalleryInfo(context: Context, galleryId: String): GalleryInfo? {
        val keys = arrayOf(
            MediaStore.Files.FileColumns.BUCKET_ID,
            MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME,
            MediaStore.Files.FileColumns.DATA
        )
        val cursor = context.contentResolver.query(
            allUri,
            keys,
            "${MediaStore.Files.FileColumns.BUCKET_ID} = ?",
            arrayOf(galleryId),
            null
        ) ?: return null
        cursor.use {
            if (!it.moveToNext()) {
                return null
            }
            val path = it.getStringOrNull(MediaStore.Files.FileColumns.DATA) ?: return null
            val name = it.getStringOrNull(MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME)
                ?: return null
            val galleryPath = File(path).parentFile?.absolutePath ?: return null
            return GalleryInfo(galleryPath, galleryId, name)
        }
    }

    override fun saveVideo(
        context: Context,
        path: String,
        title: String,
        desc: String,
        relativePath: String?
    ): AssetEntity? {
        val inputStream = FileInputStream(path)
        val cr = context.contentResolver
        val timestamp = System.currentTimeMillis() / 1000
        val typeFromStream = URLConnection.guessContentTypeFromStream(inputStream)
            ?: "video/${File(path).extension}"
        val dir = Environment.getExternalStorageDirectory()
        val savePath = File(path).absolutePath.startsWith(dir.path)
        val info = VideoUtils.getPropertiesUseMediaPlayer(path)

        val values = ContentValues().apply {
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
            if (savePath)
                put(MediaStore.Video.VideoColumns.DATA, path)
        }

        val uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val contentUri = cr.insert(uri, values) ?: return null
        val id = ContentUris.parseId(contentUri)
        val assetEntity = getAssetEntity(context, id.toString())
        if (savePath) {
            inputStream.close()
        } else {
            val tmpPath = assetEntity?.path!!
            tmpPath.checkDirs()
            val tmpFile = File(tmpPath)
            val targetPath = "${tmpFile.parent}/$title"
            val targetFile = File(targetPath)
            if (targetFile.exists()) {
                throw IOException("save target path is ")
            }
            tmpFile.renameTo(targetFile)
            val updateDataValues = ContentValues().apply {
                put(MediaStore.Video.VideoColumns.DATA, targetPath)
            }
            cr.update(contentUri, updateDataValues, null, null)
            val outputStream = FileOutputStream(targetFile)
            outputStream.use { os -> inputStream.use { it.copyTo(os) } }
            assetEntity.path = targetPath
        }
        cr.notifyChange(contentUri, null)
        return assetEntity
    }

    private data class GalleryInfo(val path: String, val galleryId: String, val galleryName: String)
}
