package top.kikt.imagescanner.core.utils

import android.content.Context
import android.database.Cursor
import android.graphics.Bitmap
import android.provider.MediaStore
import android.provider.MediaStore.VOLUME_EXTERNAL
import top.kikt.imagescanner.core.cache.CacheContainer
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.GalleryEntity

/// create 2019-09-11 by cai


interface IDBUtils {

    companion object {

        val storeImageKeys = arrayOf(
                MediaStore.Images.Media.DISPLAY_NAME, // 显示的名字
                MediaStore.Images.Media.DATA, // 数据
                MediaStore.Images.Media._ID, // id
                MediaStore.Images.Media.TITLE, // id
                MediaStore.Images.Media.BUCKET_ID, // dir id 目录
                MediaStore.Images.Media.BUCKET_DISPLAY_NAME, // dir name 目录名字
                MediaStore.Images.Media.WIDTH, // 宽
                MediaStore.Images.Media.HEIGHT, // 高
                MediaStore.Images.Media.MIME_TYPE, // 高
                MediaStore.Images.Media.DATE_TAKEN //日期
        )

        val storeVideoKeys = arrayOf(
                MediaStore.Video.Media.DISPLAY_NAME, // 显示的名字
                MediaStore.Video.Media.DATA, // 数据
                MediaStore.Video.Media._ID, // id
                MediaStore.Video.Media.TITLE, // id
                MediaStore.Video.Media.BUCKET_ID, // dir id 目录
                MediaStore.Video.Media.BUCKET_DISPLAY_NAME, // dir name 目录名字
                MediaStore.Video.Media.DATE_TAKEN, //日期
                MediaStore.Video.Media.WIDTH, // 宽
                MediaStore.Video.Media.HEIGHT, // 高
                MediaStore.Video.Media.MIME_TYPE, // 高
                MediaStore.Video.Media.DURATION //时长
        )

        val typeKeys = arrayOf(
                MediaStore.Files.FileColumns.MEDIA_TYPE,
                MediaStore.Images.Media.DISPLAY_NAME
        )

        val storeBucketKeys = arrayOf(
                MediaStore.Images.Media.BUCKET_ID,
                MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME
        )

    }

    val allUri
        get() = MediaStore.Files.getContentUri(VOLUME_EXTERNAL)

    fun getGalleryList(context: Context, requestType: Int = 0, timeStamp: Long): List<GalleryEntity>

    fun getAssetFromGalleryId(context: Context, galleryId: String, page: Int, pageSize: Int, requestType: Int = 0, timeStamp: Long, cacheContainer: CacheContainer? = null): List<AssetEntity>
    fun getAssetEntity(context: Context, id: String): AssetEntity?

    fun getMediaType(type: Int): Int {
        return when (type) {
            MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE -> 1
            MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO -> 2
            else -> 0
        }
    }

    fun Cursor.getInt(columnName: String): Int {
        return getInt(getColumnIndex(columnName))
    }

    fun Cursor.getString(columnName: String): String {
        return getString(getColumnIndex(columnName))
    }

    fun Cursor.getLong(columnName: String): Long {
        return getLong(getColumnIndex(columnName))
    }

    fun getGalleryEntity(context: Context, galleryId: String, type: Int, timeStamp: Long): GalleryEntity?

    fun clearCache()

    fun getFilePath(context: Context, id: String): String?

    fun getThumb(context: Context, id: String, width: Int, height: Int): Bitmap?

}