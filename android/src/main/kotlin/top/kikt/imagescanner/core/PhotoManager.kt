package top.kikt.imagescanner.core

import android.content.Context
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.GalleryEntity
import top.kikt.imagescanner.core.utils.DBUtils

/// create 2019-09-05 by cai


class PhotoManager(private val context: Context) {

    fun getGalleryList(): List<GalleryEntity> {
        return DBUtils.getGalleryList(context)
    }

    fun getAssetList(galleryId: String, page: Int, pageCount: Int, typeInt: Int = 0): List<AssetEntity> {
       return DBUtils.getAssetFromGalleryId(context, galleryId, page, pageCount, typeInt)
    }
}