package top.kikt.imagescanner.core

import android.content.Context
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.GalleryEntity
import top.kikt.imagescanner.core.utils.AndroidQDBUtils
import top.kikt.imagescanner.core.utils.DBUtils
import top.kikt.imagescanner.core.utils.IDBUtils
import top.kikt.imagescanner.old.ResultHandler
import top.kikt.imagescanner.thumb.ThumbnailUtil
import java.io.File

/// create 2019-09-05 by cai
/// Do some business logic assembly
class PhotoManager(private val context: Context) {

    companion object {
        const val ALL_ID = "isAll"
    }

    var androidQExperimental: Boolean = false
        set(value) {
            field = value
            if (value) {
                dbUtils = AndroidQDBUtils
            } else {
                dbUtils = DBUtils
            }
        }

    private var dbUtils: IDBUtils = DBUtils

    fun getGalleryList(type: Int, timeStamp: Long, hasAll: Boolean): List<GalleryEntity> {
        val fromDb = dbUtils.getGalleryList(context, type, timeStamp)

        if (!hasAll) {
            return fromDb
        }

        // make is all to the gallery list
        val entity = fromDb.run {
            var count = 0
            for (item in this) {
                count += item.length
            }
            GalleryEntity(ALL_ID, "Recent", count, type, true)
        }

        return listOf(entity) + fromDb
    }

    fun getAssetList(galleryId: String, page: Int, pageCount: Int, typeInt: Int = 0, timeStamp: Long): List<AssetEntity> {
        val gId = if (galleryId == ALL_ID) "" else galleryId
        return dbUtils.getAssetFromGalleryId(context, gId, page, pageCount, typeInt, timeStamp)
    }

    fun getThumb(id: String, width: Int, height: Int, resultHandler: ResultHandler) {
        val asset = dbUtils.getAssetEntity(context, id)
        if (asset == null) {
            resultHandler.replyError("The asset not found!")
            return
        }
        if (!androidQExperimental) {
            ThumbnailUtil.getThumbnailByGlide(context, asset.path, width, height, resultHandler.result)
        } else {
            // need use android Q  MediaStore thumbnail api
            val filePath = DBUtils.getFilePath(context, id)
            if (filePath == null) {
                resultHandler.replyError("The file not found, so thumb can't be decode", null, null)
                return
            }
            ThumbnailUtil.getThumbnailByGlide(context, filePath, width, height, resultHandler.result)
        }
    }

    fun getOriginBytes(id: String, resultHandler: ResultHandler) {
        val asset = dbUtils.getAssetEntity(context, id)

        if (asset == null) {
            resultHandler.replyError("The asset not found")
            return
        }

        val byteArray = File(asset.path).readBytes()
        resultHandler.reply(byteArray)
    }

    fun clearCache() {
        dbUtils.clearCache()
    }

    fun getPathEntity(id: String, type: Int, timestamp: Long): GalleryEntity? {
        if (id == ALL_ID) {
            val allGalleryList = dbUtils.getGalleryList(context, type, timestamp)
            return if (allGalleryList.isEmpty()) {
                null
            } else {
                // make is all to the gallery list
                allGalleryList.run {
                    var count = 0
                    for (item in this) {
                        count += item.length
                    }
                    GalleryEntity(ALL_ID, "Recent", count, type, true)
                }
            }
        }
        return dbUtils.getGalleryEntity(context, id, type, timestamp)
    }

    fun getFile(id: String, resultHandler: ResultHandler) {
        val path = dbUtils.getFilePath(context, id)
        resultHandler.reply(path)
    }

}