package com.fluttercandies.photo_manager.core.utils

import android.content.ContentValues
import android.content.Context
import android.provider.BaseColumns._ID
import android.provider.MediaStore
import android.util.Log
import androidx.exifinterface.media.ExifInterface
import com.fluttercandies.photo_manager.core.PhotoManager
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.entity.AssetPathEntity
import com.fluttercandies.photo_manager.core.entity.filter.FilterOption
import java.io.File
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

/// Call the MediaStore API and get entity for the data.
@Suppress("Deprecation", "InlinedApi")
object DBUtils : IDBUtils {
    private val locationKeys = arrayOf(
        MediaStore.Images.ImageColumns.LONGITUDE,
        MediaStore.Images.ImageColumns.LATITUDE
    )

    override fun keys(): Array<String> =
        (IDBUtils.storeImageKeys + IDBUtils.storeVideoKeys + IDBUtils.typeKeys + locationKeys).distinct()
            .toTypedArray()

    override fun getAssetPathList(
        context: Context,
        requestType: Int,
        option: FilterOption
    ): List<AssetPathEntity> {
        val list = ArrayList<AssetPathEntity>()
        val args = ArrayList<String>()
        val where = option.makeWhere(requestType, args)
//        val where = makeWhere(requestType, option, args)
        val selection =
            "${MediaStore.MediaColumns.BUCKET_ID} IS NOT NULL $where) GROUP BY (${MediaStore.MediaColumns.BUCKET_ID}"
        val cursor = context.contentResolver.logQuery(
            allUri,
            IDBUtils.storeBucketKeys + arrayOf("count(1)"),
            selection,
            args.toTypedArray(),
            null
        ) ?: return list
        cursor.use {
            while (it.moveToNext()) {
                val id = it.getString(0)
                val name = it.getString(1) ?: ""
                val assetCount = it.getInt(2)
                val entity = AssetPathEntity(id, name, assetCount, 0)
                if (option.containsPathModified) {
                    injectModifiedDate(context, entity)
                }
                list.add(entity)
            }
        }
        return list
    }


    override fun getMainAssetPathEntity(
        context: Context,
        requestType: Int,
        option: FilterOption
    ): List<AssetPathEntity> {
        val list = ArrayList<AssetPathEntity>()
        val projection = IDBUtils.storeBucketKeys + arrayOf("count(1)")
        val args = ArrayList<String>()
        val where = option.makeWhere(requestType, args)
        val selections =
            "${MediaStore.MediaColumns.BUCKET_ID} IS NOT NULL $where"

        val cursor = context.contentResolver.logQuery(
            allUri,
            projection,
            selections,
            args.toTypedArray(),
            null
        ) ?: return list
        cursor.use {
            if (it.moveToNext()) {
                val countIndex = projection.indexOf("count(1)")
                val assetCount = it.getInt(countIndex)
                val assetPathEntity = AssetPathEntity(
                    PhotoManager.ALL_ID,
                    PhotoManager.ALL_ALBUM_NAME,
                    assetCount,
                    requestType,
                    true
                )
                list.add(assetPathEntity)
            }
        }
        return list
    }

    override fun getAssetPathEntityFromId(
        context: Context,
        pathId: String,
        type: Int,
        option: FilterOption
    ): AssetPathEntity? {
        val args = ArrayList<String>()
        val idSelection: String
        if (pathId == "") {
            idSelection = ""
        } else {
            idSelection = "AND ${MediaStore.MediaColumns.BUCKET_ID} = ?"
            args.add(pathId)
        }
        val where = option.makeWhere(type, args)
        val selection =
            "${MediaStore.MediaColumns.BUCKET_ID} IS NOT NULL $where $idSelection) GROUP BY (${MediaStore.MediaColumns.BUCKET_ID}"
        val cursor = context.contentResolver.logQuery(
            allUri,
            IDBUtils.storeBucketKeys + arrayOf("count(1)"),
            selection,
            args.toTypedArray(),
            null
        ) ?: return null
        cursor.use {
            return if (it.moveToNext()) {
                val id = it.getString(0)
                val name = it.getString(1) ?: ""
                val assetCount = it.getInt(2)
                AssetPathEntity(id, name, assetCount, 0)
            } else {
                null
            }
        }
    }

    override fun getAssetListPaged(
        context: Context,
        pathId: String,
        page: Int,
        size: Int,
        requestType: Int,
        option: FilterOption
    ): List<AssetEntity> {
        val isAll = pathId.isEmpty()
        val list = ArrayList<AssetEntity>()
        val args = ArrayList<String>()
        if (!isAll) {
            args.add(pathId)
        }
        val where = option.makeWhere(requestType, args)
        val keys = keys()
        val selection = if (isAll) {
            "${MediaStore.MediaColumns.BUCKET_ID} IS NOT NULL $where"
        } else {
            "${MediaStore.MediaColumns.BUCKET_ID} = ? $where"
        }
        val sortOrder = getSortOrder(page * size, size, option)
        val cursor = context.contentResolver.logQuery(
            allUri,
            keys,
            selection,
            args.toTypedArray(),
            sortOrder
        ) ?: return list
        cursor.use {
            while (it.moveToNext()) {
                it.toAssetEntity(context)?.apply {
                    list.add(this)
                }
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
        val args = ArrayList<String>()
        if (!isAll) {
            args.add(galleryId)
        }
        val where = option.makeWhere(requestType, args)
        val keys = keys()

        val selection = if (isAll) {
            "${MediaStore.MediaColumns.BUCKET_ID} IS NOT NULL $where"
        } else {
            "${MediaStore.MediaColumns.BUCKET_ID} = ? $where"
        }
        val pageSize = end - start
        val sortOrder = getSortOrder(start, pageSize, option)
        val cursor = context.contentResolver.logQuery(
            allUri,
            keys,
            selection,
            args.toTypedArray(),
            sortOrder
        ) ?: return list
        cursor.use {
            while (it.moveToNext()) {
                it.toAssetEntity(context)?.apply {
                    list.add(this)
                }
            }
        }
        return list
    }

    override fun getAssetEntity(
        context: Context,
        id: String,
        checkIfExists: Boolean
    ): AssetEntity? {
        val keys =
            (IDBUtils.storeImageKeys + IDBUtils.storeVideoKeys + locationKeys + IDBUtils.typeKeys).distinct()
                .toTypedArray()
        val selection = "${MediaStore.MediaColumns._ID} = ?"
        val args = arrayOf(id)

        val cursor = context.contentResolver.logQuery(
            allUri,
            keys,
            selection,
            args,
            null
        ) ?: return null
        cursor.use {
            return if (it.moveToNext()) {
                it.toAssetEntity(context, checkIfExists)
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
            MediaStore.MediaColumns.TITLE,
            MediaStore.MediaColumns.DATE_ADDED,
            MediaStore.MediaColumns.DATE_MODIFIED,
            MediaStore.MediaColumns.DURATION,
            MediaStore.Video.VideoColumns.LONGITUDE,
            MediaStore.Video.VideoColumns.LATITUDE,
            MediaStore.MediaColumns.WIDTH,
            MediaStore.MediaColumns.HEIGHT
        )
        val mediaType = convertTypeToMediaType(asset.type)
        if (mediaType != MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO) {
            copyKeys.add(MediaStore.Video.VideoColumns.DESCRIPTION)
        }

        val cursor = cr.logQuery(
            allUri,
            copyKeys.toTypedArray() + arrayOf(MediaStore.MediaColumns.DATA),
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
            put(MediaStore.MediaColumns.DATA, outputPath)
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
        val cursor = cr.logQuery(
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
            put(MediaStore.MediaColumns.BUCKET_ID, galleryId)
            put(MediaStore.MediaColumns.BUCKET_DISPLAY_NAME, targetGalleryInfo.galleryName)
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
            val cursor = cr.logQuery(
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
        val cursor = context.contentResolver.logQuery(
            allUri,
            arrayOf(MediaStore.MediaColumns.BUCKET_ID, MediaStore.MediaColumns.DATA),
            "${MediaStore.MediaColumns._ID} = ?",
            arrayOf(assetId),
            null
        ) ?: return null
        cursor.use {
            if (!it.moveToNext()) {
                return null
            }
            val galleryID = it.getString(0)
            val path = it.getString(1)
            return Pair(galleryID, File(path).parent)
        }
    }

    private fun getGalleryInfo(context: Context, galleryId: String): GalleryInfo? {
        val keys = arrayOf(
            MediaStore.MediaColumns.BUCKET_ID,
            MediaStore.MediaColumns.BUCKET_DISPLAY_NAME,
            MediaStore.MediaColumns.DATA
        )
        val cursor = context.contentResolver.logQuery(
            allUri,
            keys,
            "${MediaStore.MediaColumns.BUCKET_ID} = ?",
            arrayOf(galleryId),
            null
        ) ?: return null
        cursor.use {
            if (!it.moveToNext()) {
                return null
            }
            val path = it.getStringOrNull(MediaStore.MediaColumns.DATA) ?: return null
            val name = it.getStringOrNull(MediaStore.MediaColumns.BUCKET_DISPLAY_NAME)
                ?: return null
            val galleryPath = File(path).parentFile?.absolutePath ?: return null
            return GalleryInfo(galleryPath, galleryId, name)
        }
    }

    private data class GalleryInfo(val path: String, val galleryId: String, val galleryName: String)
}
