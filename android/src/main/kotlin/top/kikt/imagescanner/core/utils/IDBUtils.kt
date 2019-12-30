package top.kikt.imagescanner.core.utils

import android.content.Context
import android.database.Cursor
import android.graphics.Bitmap
import android.net.Uri
import android.provider.MediaStore
import android.provider.MediaStore.VOLUME_EXTERNAL
import top.kikt.imagescanner.core.cache.CacheContainer
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.GalleryEntity
import java.io.InputStream


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
            MediaStore.Images.Media.DATE_MODIFIED, // 修改时间
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
            MediaStore.Images.Media.DATE_MODIFIED, // 修改时间
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
    
    val allUri: Uri
        get() = MediaStore.Files.getContentUri(VOLUME_EXTERNAL)
    
    
    fun sizeWhere(type: Int?): String {
        // return "" // 5491
        // image : 5484
        
        if (type == null || type == 2) {
            return ""
        }
        
        val size = "${MediaStore.MediaColumns.WIDTH} > 0 AND ${MediaStore.MediaColumns.HEIGHT} > 0"
        
        return if (type == 1) {
            "AND $size"
        } else {
            "AND (${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO} or (" +
                "${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} AND $size))"
        }
    }
    
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
    
    fun getThumb(context: Context, id: String, width: Int, height: Int, type: Int?): Bitmap?
    
    fun getAssetFromGalleryIdRange(context: Context, gId: String, start: Int, end: Int, requestType: Int, timestamp: Long): List<AssetEntity>
    
    fun deleteWithIds(context: Context, ids: List<String>): List<String> {
        val where = "${MediaStore.MediaColumns._ID} in (?)"
        val idsArgs = ids.joinToString()
        return try {
            val lines = context.contentResolver.delete(allUri, where, arrayOf(idsArgs))
            if (lines > 0) {
                ids
            } else {
                emptyList()
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    fun saveImage(context: Context, image: ByteArray, title: String, desc: String): AssetEntity?
    
    fun saveVideo(context: Context, inputStream: InputStream, title: String, desc: String): AssetEntity?
    
    fun exists(context: Context, id: String): Boolean{
            val columns = arrayOf(MediaStore.Files.FileColumns._ID)
            context.contentResolver.query(DBUtils.allUri, columns, "MediaStore.Files.FileColumns._ID = ?", arrayOf(id), null).use {
                if (it == null) {
                    return false
                }
                return it.count >=1
            }
    }
    
}