package top.kikt.imagescanner.core.utils

import android.annotation.SuppressLint
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.MediaStore
import android.provider.MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
import android.provider.MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
import top.kikt.imagescanner.core.cache.CacheContainer
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.GalleryEntity

/// create 2019-09-05 by cai
/// Call the MediaStore API and get entity for the data.
object DBUtils {

    private val cacheContainer = CacheContainer()

    private const val TAG = "DBUtils"

    private val storeImageKeys = arrayOf(
            MediaStore.Images.Media.DISPLAY_NAME, // 显示的名字
            MediaStore.Images.Media.DATA, // 数据
            MediaStore.Images.Media.LONGITUDE, // 经度
            MediaStore.Images.Media._ID, // id
            MediaStore.Images.Media.MINI_THUMB_MAGIC, // id
            MediaStore.Images.Media.TITLE, // id
            MediaStore.Images.Media.BUCKET_ID, // dir id 目录
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME, // dir name 目录名字
            MediaStore.Images.Media.WIDTH, // 宽
            MediaStore.Images.Media.HEIGHT, // 高
            MediaStore.Images.Media.DATE_TAKEN //日期
    )

    private val storeVideoKeys = arrayOf(
            MediaStore.Video.Media.DISPLAY_NAME, // 显示的名字
            MediaStore.Video.Media.DATA, // 数据
            MediaStore.Video.Media.LONGITUDE, // 经度
            MediaStore.Video.Media._ID, // id
            MediaStore.Video.Media.MINI_THUMB_MAGIC, // id
            MediaStore.Video.Media.TITLE, // id
            MediaStore.Video.Media.BUCKET_ID, // dir id 目录
            MediaStore.Video.Media.BUCKET_DISPLAY_NAME, // dir name 目录名字
            MediaStore.Video.Media.DATE_TAKEN, //日期
            MediaStore.Video.Media.WIDTH, // 宽
            MediaStore.Video.Media.HEIGHT, // 高
            MediaStore.Video.Media.DURATION //时长
    )

    private val typeKeys = arrayOf(
            MediaStore.Files.FileColumns.MEDIA_TYPE
    )

    private val storeBucketKeys = arrayOf(
            MediaStore.Images.Media.BUCKET_ID,
            MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME
    )

    private val allUri = MediaStore.Files.getContentUri("external")
    private val imageUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
    private val videoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI

    private fun convertTypeToUri(type: Int): Uri {
        return when (type) {
            1 -> imageUri
            2 -> videoUri
            else -> allUri
        }
    }

    @SuppressLint("Recycle")
    fun getGalleryList(context: Context, requestType: Int = 0, timeStamp: Long): List<GalleryEntity> {
        val list = ArrayList<GalleryEntity>()
        val uri = allUri
        val projection = storeBucketKeys + arrayOf("count(1)")

        val args = ArrayList<String>()
        val typeSelection: String

        when (requestType) {
            1 -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
                args.add(MEDIA_TYPE_IMAGE.toString())

            }
            2 -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
                args.add(MEDIA_TYPE_VIDEO.toString())
            }
            else -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} in (?,?)"
                args.add(MEDIA_TYPE_IMAGE.toString())
                args.add(MEDIA_TYPE_VIDEO.toString())
            }
        }

        val dateSelection = "AND ${MediaStore.Images.Media.DATE_TAKEN} <= ?"
        args.add(timeStamp.toString())

        val selection = "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection) GROUP BY (${MediaStore.Images.Media.BUCKET_ID}"
        val cursor = context.contentResolver.query(uri, projection, selection, args.toTypedArray(), null)
                ?: return emptyList()
        while (cursor.moveToNext()) {
            val id = cursor.getString(0)
            val name = cursor.getString(1)
            val count = cursor.getInt(2)
            list.add(GalleryEntity(id, name, count, 0))
        }

        cursor.close()
        return list
    }

    fun getGalleryEntity(context: Context, galleryId: String, type: Int, timeStamp: Long): GalleryEntity? {
        val uri = allUri
        val projection = storeBucketKeys + arrayOf("count(1)")

        val args = ArrayList<String>()
        val typeSelection: String

        when (type) {
            1 -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
                args.add(MEDIA_TYPE_IMAGE.toString())
            }
            2 -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
                args.add(MEDIA_TYPE_VIDEO.toString())
            }
            else -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} in (?,?)"
                args.add(MEDIA_TYPE_IMAGE.toString())
                args.add(MEDIA_TYPE_VIDEO.toString())
            }
        }

        val dateSelection = "AND ${MediaStore.Images.Media.DATE_TAKEN} <= ?"
        args.add(timeStamp.toString())

        val idSelection: String
        if (galleryId == "") {
            idSelection = ""
        } else {
            idSelection = "AND ${MediaStore.Images.Media.BUCKET_ID} = ?"
            args.add(galleryId)
        }

        val selection = "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $idSelection) GROUP BY (${MediaStore.Images.Media.BUCKET_ID}"
        val cursor = context.contentResolver.query(uri, projection, selection, args.toTypedArray(), null) ?: return null
        return if (cursor.moveToNext()) {
            val id = cursor.getString(0)
            val name = cursor.getString(1)
            val count = cursor.getInt(2)
            cursor.close()
            GalleryEntity(id, name, count, 0)
        } else {
            cursor.close()
            null
        }
    }

    @SuppressLint("Recycle")
    fun getAssetFromGalleryId(context: Context, galleryId: String, page: Int, pageSize: Int, requestType: Int = 0, timeStamp: Long): List<AssetEntity> {
        val isAll = galleryId.isEmpty()

        val list = ArrayList<AssetEntity>()
        val uri = allUri

        val args = ArrayList<String>()
        if (!isAll) {
            args.add(galleryId)
        }
        val typeSelection: String

        when (requestType) {
            1 -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
                args.add(MEDIA_TYPE_IMAGE.toString())
            }
            2 -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
                args.add(MEDIA_TYPE_VIDEO.toString())
            }
            else -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} in (?,?)"
                args.add(MEDIA_TYPE_IMAGE.toString())
                args.add(MEDIA_TYPE_VIDEO.toString())
            }
        }

        val dateSelection = "AND ${MediaStore.Images.Media.DATE_TAKEN} <= ?"
        args.add(timeStamp.toString())

        val keys = (storeImageKeys + storeVideoKeys + typeKeys).distinct().toTypedArray()
        val selection = if (isAll) {
            "${MediaStore.Images.ImageColumns.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection"
        } else {
            "${MediaStore.Images.ImageColumns.BUCKET_ID} = ? $typeSelection $dateSelection"
        }

        val sortOrder = "${MediaStore.Images.Media.DATE_TAKEN} DESC LIMIT $pageSize OFFSET ${page * pageSize}"
        val cursor = context.contentResolver.query(uri, keys, selection, args.toTypedArray(), sortOrder)
                ?: return emptyList()

        while (cursor.moveToNext()) {
            val id = cursor.getString(MediaStore.MediaColumns._ID)
            val path = cursor.getString(MediaStore.MediaColumns.DATA)
            val date = cursor.getLong(MediaStore.Images.Media.DATE_TAKEN)
            val type = cursor.getInt(MediaStore.Files.FileColumns.MEDIA_TYPE)
            val duration = if (requestType == 1) 0 else cursor.getLong(MediaStore.Video.VideoColumns.DURATION)
            val width = cursor.getInt(MediaStore.MediaColumns.WIDTH)
            val height = cursor.getInt(MediaStore.MediaColumns.HEIGHT)
            val asset = AssetEntity(id, path, duration, date, width, height, getMediaType(type))
            list.add(asset)
            cacheContainer.putAsset(asset)
        }

        cursor.close()

        return list
    }

    @SuppressLint("Recycle")
    fun getAssetEntity(context: Context, id: String): AssetEntity? {
        val asset = cacheContainer.getAsset(id)
        if (asset != null) {
            return asset
        }

        val keys = (storeImageKeys + storeVideoKeys).distinct().toTypedArray()

        val selection = "${MediaStore.Files.FileColumns.DATA} = ?"

        val args = arrayOf(id)

        val cursor = context.contentResolver.query(allUri, keys, selection, args, null)
                ?: return null

        if (cursor.moveToNext()) {
            val databaseId = cursor.getString(MediaStore.MediaColumns._ID)
            val path = cursor.getString(MediaStore.MediaColumns.DATA)
            val date = cursor.getLong(MediaStore.Images.Media.DATE_TAKEN)
            val type = cursor.getInt(MediaStore.Files.FileColumns.MEDIA_TYPE)
            val duration = if (type == MEDIA_TYPE_IMAGE) 0 else cursor.getLong(MediaStore.Video.VideoColumns.DURATION)
            val width = cursor.getInt(MediaStore.MediaColumns.WIDTH)
            val height = cursor.getInt(MediaStore.MediaColumns.HEIGHT)
            val dbAsset = AssetEntity(databaseId, path, duration, date, width, height, getMediaType(type))

            cacheContainer.putAsset(dbAsset)

            cursor.close()
            return dbAsset
        } else {
            cursor.close()
            return null
        }
    }

    private fun getMediaType(type: Int): Int {
        return when (type) {
            MEDIA_TYPE_IMAGE -> 1
            MEDIA_TYPE_VIDEO -> 2
            else -> 0
        }
    }

    private fun Cursor.getInt(columnName: String): Int {
        return getInt(getColumnIndex(columnName))
    }

    private fun Cursor.getString(columnName: String): String {
        return getString(getColumnIndex(columnName))
    }

    private fun Cursor.getLong(columnName: String): Long {
        return getLong(getColumnIndex(columnName))
    }

    fun clearCache() {
        cacheContainer.clearCache()
    }

}