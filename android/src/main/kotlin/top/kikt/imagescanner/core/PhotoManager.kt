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

    fun getGalleryList(type: Int): List<GalleryEntity> {
        return DBUtils.getGalleryList(context, type)
    }

    fun getAssetList(galleryId: String, page: Int, pageCount: Int, typeInt: Int = 0): List<AssetEntity> {
        return DBUtils.getAssetFromGalleryId(context, galleryId, page, pageCount, typeInt)
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

}