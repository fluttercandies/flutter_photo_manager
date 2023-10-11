package com.fluttercandies.photo_manager.core

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.util.Log
import com.bumptech.glide.Glide
import com.bumptech.glide.request.FutureTarget
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.entity.AssetPathEntity
import com.fluttercandies.photo_manager.core.entity.ThumbLoadOption
import com.fluttercandies.photo_manager.core.entity.filter.FilterOption
import com.fluttercandies.photo_manager.core.utils.AndroidQDBUtils
import com.fluttercandies.photo_manager.core.utils.ConvertUtils
import com.fluttercandies.photo_manager.core.utils.DBUtils
import com.fluttercandies.photo_manager.core.utils.IDBUtils
import com.fluttercandies.photo_manager.thumb.ThumbnailUtil
import com.fluttercandies.photo_manager.util.LogUtils
import com.fluttercandies.photo_manager.util.ResultHandler
import java.io.File
import java.util.concurrent.Executors

class PhotoManager(private val context: Context) {
    companion object {
        const val ALL_ID = "isAll"
        const val ALL_ALBUM_NAME = "Recent"

        private val threadPool = Executors.newFixedThreadPool(5)
    }

    var useOldApi: Boolean = false

    private val dbUtils: IDBUtils
        get() {
            return if (useOldApi || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) DBUtils
            else AndroidQDBUtils
        }

    fun getAssetPathList(
        type: Int,
        hasAll: Boolean,
        onlyAll: Boolean,
        option: FilterOption
    ): List<AssetPathEntity> {
        if (onlyAll) {
            return dbUtils.getMainAssetPathEntity(context, type, option)
        }
        val fromDb = dbUtils.getAssetPathList(context, type, option)
        if (!hasAll) {
            return fromDb
        }
        // make is all to the gallery list
        val entity = fromDb.run {
            var assetCount = 0
            for (item in this) {
                assetCount += item.assetCount
            }
            AssetPathEntity(ALL_ID, ALL_ALBUM_NAME, assetCount, type, true)
        }

        return listOf(entity) + fromDb
    }

    fun getAssetListPaged(
        id: String,
        typeInt: Int = 0,
        page: Int,
        size: Int,
        option: FilterOption
    ): List<AssetEntity> {
        val gId = if (id == ALL_ID) "" else id
        return dbUtils.getAssetListPaged(context, gId, page, size, typeInt, option)
    }

    fun getAssetListRange(
        galleryId: String,
        type: Int,
        start: Int,
        end: Int,
        option: FilterOption
    ): List<AssetEntity> {
        val gId = if (galleryId == ALL_ID) "" else galleryId
        return dbUtils.getAssetListRange(context, gId, start, end, type, option)
    }

    fun getThumb(id: String, option: ThumbLoadOption, resultHandler: ResultHandler) {
        val width = option.width
        val height = option.height
        val quality = option.quality
        val format = option.format
        val frame = option.frame
        try {
            val asset = dbUtils.getAssetEntity(context, id)
            if (asset == null) {
                resultHandler.replyError("The asset not found!")
                return
            }
            ThumbnailUtil.getThumbnail(
                context,
                asset,
                option.width,
                option.height,
                format,
                quality,
                frame,
                resultHandler,
            )
        } catch (e: Exception) {
            Log.e(LogUtils.TAG, "get $id thumbnail error, width : $width, height: $height", e)
            dbUtils.logRowWithId(context, id)
            resultHandler.replyError("201", "get thumb error", e)
        }
    }

    fun getOriginBytes(id: String, resultHandler: ResultHandler, needLocationPermission: Boolean) {
        val asset = dbUtils.getAssetEntity(context, id)
        if (asset == null) {
            resultHandler.replyError("The asset not found")
            return
        }
        try {
            val byteArray = dbUtils.getOriginBytes(context, asset, needLocationPermission)
            resultHandler.reply(byteArray)
        } catch (e: Exception) {
            dbUtils.logRowWithId(context, id)
            resultHandler.replyError("202", "get originBytes error", e)
        }
    }

    fun clearFileCache() {
        ThumbnailUtil.clearCache(context)
        dbUtils.clearFileCache(context)
    }

    fun fetchPathProperties(id: String, type: Int, option: FilterOption): AssetPathEntity? {
        if (id == ALL_ID) {
            val allGalleryList = dbUtils.getAssetPathList(context, type, option)
            return if (allGalleryList.isEmpty()) {
                null
            } else {
                // make is all to the gallery list
                allGalleryList.run {
                    var assetCount = 0
                    for (item in this) {
                        assetCount += item.assetCount
                    }
                    AssetPathEntity(ALL_ID, ALL_ALBUM_NAME, assetCount, type, true).apply {
                        if (option.containsPathModified) {
                            dbUtils.injectModifiedDate(context, this)
                        }
                    }
                }
            }
        }
        val galleryEntity = dbUtils.getAssetPathEntityFromId(context, id, type, option)
        if (galleryEntity != null && option.containsPathModified) {
            dbUtils.injectModifiedDate(context, galleryEntity)
        }

        return galleryEntity
    }

    fun getFile(id: String, isOrigin: Boolean, resultHandler: ResultHandler) {
        val path = dbUtils.getFilePath(context, id, isOrigin)
        resultHandler.reply(path)
    }

    fun saveImage(
        image: ByteArray,
        title: String,
        description: String,
        relativePath: String?
    ): AssetEntity? {
        return dbUtils.saveImage(context, image, title, description, relativePath)
    }

    fun saveImage(
        path: String,
        title: String,
        description: String,
        relativePath: String?
    ): AssetEntity? {
        return dbUtils.saveImage(context, path, title, description, relativePath)
    }

    fun saveVideo(path: String, title: String, desc: String, relativePath: String?): AssetEntity? {
        if (!File(path).exists()) {
            return null
        }
        return dbUtils.saveVideo(context, path, title, desc, relativePath)
    }

    fun assetExists(id: String, resultHandler: ResultHandler) {
        val exists: Boolean = dbUtils.assetExists(context, id)
        resultHandler.reply(exists)
    }

    fun getLocation(id: String): Map<String, Double> {
        val exifInfo = dbUtils.getExif(context, id)
        val latLong = exifInfo?.latLong
        return if (latLong == null) {
            mapOf("lat" to 0.0, "lng" to 0.0)
        } else {
            mapOf("lat" to latLong[0], "lng" to latLong[1])
        }
    }

    fun getMediaUri(id: Long, type: Int): String {
        return dbUtils.getMediaUri(context, id, type)
    }

    fun copyToGallery(assetId: String, galleryId: String, resultHandler: ResultHandler) {
        try {
            val assetEntity = dbUtils.copyToGallery(context, assetId, galleryId)
            if (assetEntity == null) {
                resultHandler.reply(null)
                return
            }
            resultHandler.reply(ConvertUtils.convertAsset(assetEntity))
        } catch (e: Exception) {
            LogUtils.error(e)
            resultHandler.reply(null)
        }
    }

    fun moveToGallery(assetId: String, albumId: String, resultHandler: ResultHandler) {
        try {
            val assetEntity = dbUtils.moveToGallery(context, assetId, albumId)
            if (assetEntity == null) {
                resultHandler.reply(null)
                return
            }
            resultHandler.reply(ConvertUtils.convertAsset(assetEntity))
        } catch (e: Exception) {
            LogUtils.error(e)
            resultHandler.reply(null)
        }
    }

    fun removeAllExistsAssets(resultHandler: ResultHandler) {
        val result = dbUtils.removeAllExistsAssets(context)
        resultHandler.reply(result)
    }

    fun fetchEntityProperties(id: String): AssetEntity? {
        return dbUtils.getAssetEntity(context, id)
    }

    fun getUri(id: String): Uri? {
        val asset = dbUtils.getAssetEntity(context, id)
        return asset?.getUri()
    }

    private val cacheFutures = ArrayList<FutureTarget<Bitmap>>()

    fun requestCache(ids: List<String>, option: ThumbLoadOption, resultHandler: ResultHandler) {
        val pathList = dbUtils.getAssetsPath(context, ids)
        for (s in pathList) {
            val future = ThumbnailUtil.requestCacheThumb(context, s, option)
            cacheFutures.add(future)
        }
        resultHandler.reply(1)
        val needExecuteFutures = cacheFutures.toList()
        for (cacheFuture in needExecuteFutures) {
            threadPool.execute {
                if (cacheFuture.isCancelled) {
                    return@execute
                }

                try {
                    cacheFuture.get()
                } catch (e: Exception) {
                    LogUtils.error(e)
                }
            }
        }
    }

    fun cancelCacheRequests() {
        val needCancelFutures = cacheFutures.toList()
        cacheFutures.clear()
        for (futureTarget in needCancelFutures) {
            Glide.with(context).clear(futureTarget)
        }
    }

    fun getColumnNames(resultHandler: ResultHandler) {
        val columnNames = dbUtils.getColumnNames(context)
        resultHandler.reply(columnNames)
    }

    fun getAssetCount(resultHandler: ResultHandler, option: FilterOption, requestType: Int) {
        val assetCount = dbUtils.getAssetCount(context, option, requestType)
        resultHandler.reply(assetCount)
    }

    fun getAssetsByRange(
        resultHandler: ResultHandler,
        option: FilterOption,
        start: Int,
        end: Int,
        requestType: Int
    ) {
        val list = dbUtils.getAssetsByRange(context, option, start, end, requestType)
        resultHandler.reply(ConvertUtils.convertAssets(list))
    }
}
