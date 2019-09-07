package top.kikt.imagescanner.core

import android.content.Context
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.GalleryEntity
import top.kikt.imagescanner.core.utils.DBUtils
import top.kikt.imagescanner.old.ResultHandler
import top.kikt.imagescanner.thumb.ThumbnailUtil
import java.io.File

/// create 2019-09-05 by cai


class PhotoManager(private val context: Context) {

    companion object {
        const val ALL_ID = "isAll"
    }

    fun getGalleryList(type: Int): List<GalleryEntity> {
        val fromDb = DBUtils.getGalleryList(context, type)

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

    fun getAssetList(galleryId: String, page: Int, pageCount: Int, typeInt: Int = 0): List<AssetEntity> {
        val gId = if (galleryId == ALL_ID) "" else galleryId
        return DBUtils.getAssetFromGalleryId(context, gId, page, pageCount, typeInt)
    }

    fun getThumb(id: String, width: Int, height: Int, resultHandler: ResultHandler) {
        val asset = DBUtils.getAssetEntity(context, id)
        if (asset == null) {
            resultHandler.replyError("The asset not found!")
            return
        }
        ThumbnailUtil.getThumbnailByGlide(context, asset.path, width, height, resultHandler.result)
    }

    fun getOriginBytes(id: String, resultHandler: ResultHandler) {
        val asset = DBUtils.getAssetEntity(context, id)

        if (asset == null) {
            resultHandler.replyError("The asset not found")
            return
        }

        val byteArray = File(asset.path).readBytes()
        resultHandler.reply(byteArray)
    }

    fun clearCache() {
        DBUtils.clearCache()
    }

}