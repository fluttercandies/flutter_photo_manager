package top.kikt.imagescanner.core.utils

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.provider.MediaStore
import android.provider.MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
import android.provider.MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
import top.kikt.imagescanner.core.cache.CacheContainer
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.GalleryEntity
import top.kikt.imagescanner.core.utils.IDBUtils.Companion.storeBucketKeys
import top.kikt.imagescanner.core.utils.IDBUtils.Companion.storeImageKeys
import top.kikt.imagescanner.core.utils.IDBUtils.Companion.storeVideoKeys
import top.kikt.imagescanner.core.utils.IDBUtils.Companion.typeKeys
import java.io.File


/// create 2019-09-05 by cai
/// Call the MediaStore API and get entity for the data.
@Suppress("DEPRECATION")
object DBUtils : IDBUtils {

    private const val TAG = "DBUtils"

    private val imageUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
    private val videoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI

    private val cacheContainer = CacheContainer()

    private fun convertTypeToUri(type: Int): Uri {
        return when (type) {
            1 -> imageUri
            2 -> videoUri
            else -> allUri
        }
    }

    @SuppressLint("Recycle")
    override fun getGalleryList(context: Context, requestType: Int, timeStamp: Long): List<GalleryEntity> {
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

    override fun getGalleryEntity(context: Context, galleryId: String, type: Int, timeStamp: Long): GalleryEntity? {
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

    override fun getThumb(context: Context, id: String, width: Int, height: Int): Bitmap? {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    @SuppressLint("Recycle")
    override fun getAssetFromGalleryId(context: Context, galleryId: String, page: Int, pageSize: Int, requestType: Int, timeStamp: Long, cacheContainer: CacheContainer?): List<AssetEntity> {
        val cache = cacheContainer ?: this.cacheContainer

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
            val displayName = File(path).name

            val asset = AssetEntity(id, path, duration, date, width, height, getMediaType(type), displayName)
            list.add(asset)
            cache.putAsset(asset)
        }

        cursor.close()

        return list
    }

    @SuppressLint("Recycle")
    override fun getAssetEntity(context: Context, id: String): AssetEntity? {
        val asset = cacheContainer.getAsset(id)
        if (asset != null) {
            return asset
        }

        val keys = (storeImageKeys + storeVideoKeys).distinct().toTypedArray()

        val selection = "${MediaStore.Files.FileColumns._ID} = ?"

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
            val displayName = File(path).name

            val dbAsset = AssetEntity(databaseId, path, duration, date, width, height, getMediaType(type), displayName)
            cacheContainer.putAsset(dbAsset)

            cursor.close()
            return dbAsset
        } else {
            cursor.close()
            return null
        }
    }

    override fun getFilePath(context: Context, id: String): String? {
        val assetEntity = getAssetEntity(context, id) ?: return null
        return assetEntity.path
    }

    override fun clearCache() {
        cacheContainer.clearCache()
    }

}