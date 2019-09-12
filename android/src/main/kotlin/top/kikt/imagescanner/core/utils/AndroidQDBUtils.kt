package top.kikt.imagescanner.core.utils

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import androidx.annotation.RequiresApi
import top.kikt.imagescanner.core.cache.AndroidQCache
import top.kikt.imagescanner.core.cache.CacheContainer
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.GalleryEntity

/// create 2019-09-11 by cai
@RequiresApi(Build.VERSION_CODES.Q)
object AndroidQDBUtils : IDBUtils {
    private val cacheContainer = CacheContainer()

    private var androidQCache = AndroidQCache()

    private val galleryKeys = arrayOf(
            MediaStore.Images.Media.BUCKET_ID,
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME
    )

    @SuppressLint("Recycle")
    override fun getGalleryList(context: Context, requestType: Int, timeStamp: Long): List<GalleryEntity> {
        val list = ArrayList<GalleryEntity>()

        val args = ArrayList<String>()
        val typeSelection: String

        when (requestType) {
            1 -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
                args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString())

            }
            2 -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
                args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString())
            }
            else -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} in (?,?)"
                args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString())
                args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString())
            }
        }

        val dateSelection = "AND ${MediaStore.MediaColumns.DATE_ADDED} <= ?"
        args.add(timeStamp.toString())

        val selections = "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection"

        val cursor = context.contentResolver.query(allUri, galleryKeys, selections, args.toTypedArray(), null)
                ?: return list

        val nameMap = HashMap<String, String>()
        val countMap = HashMap<String, Int>()

        while (cursor.moveToNext()) {
            val galleryId = cursor.getString(0)

            if (nameMap.containsKey(galleryId)) {
                countMap[galleryId] = countMap[galleryId]!! + 1
                continue
            }
            val galleryName = cursor.getString(1)

            nameMap[galleryId] = galleryName
            countMap[galleryId] = 1
        }

        nameMap.forEach {
            val id = it.key
            val name = it.value
            val count = countMap[id]!!

            val entity = GalleryEntity(id, name, count, requestType, false)
            list.add(entity)
        }

        cursor.close()

        return list
    }

    @SuppressLint("Recycle")
    override fun getAssetFromGalleryId(context: Context, galleryId: String, page: Int, pageSize: Int, requestType: Int, timeStamp: Long, cacheContainer: CacheContainer?): List<AssetEntity> {
        val cache = cacheContainer ?: this.cacheContainer

        val isAll = galleryId.isEmpty()

        val list = ArrayList<AssetEntity>()
        val uri = DBUtils.allUri

        val args = ArrayList<String>()
        if (!isAll) {
            args.add(galleryId)
        }
        val typeSelection: String

        when (requestType) {
            1 -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
                args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString())
            }
            2 -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
                args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString())
            }
            else -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} in (?,?)"
                args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString())
                args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString())
            }
        }

        val dateSelection = "AND ${MediaStore.Images.Media.DATE_ADDED} <= ?"
        args.add(timeStamp.toString())

        val keys = (IDBUtils.storeImageKeys + IDBUtils.storeVideoKeys + IDBUtils.typeKeys).distinct().toTypedArray()
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
            val displayName = cursor.getString(MediaStore.Images.Media.DISPLAY_NAME)

            val asset = AssetEntity(id, path, duration, date, width, height, DBUtils.getMediaType(type), displayName)
            list.add(asset)
            cache.putAsset(asset)
        }

        cursor.close()

        return list

    }

    override fun getAssetEntity(context: Context, id: String): AssetEntity? {
        val asset = cacheContainer.getAsset(id)
        if (asset != null) {
            return asset
        }

        val keys = (IDBUtils.storeImageKeys + IDBUtils.storeVideoKeys).distinct().toTypedArray()

        val selection = "${MediaStore.Files.FileColumns._ID} = ?"

        val args = arrayOf(id)

        val cursor = context.contentResolver.query(DBUtils.allUri, keys, selection, args, null)
        cursor?.use {
            if (cursor.moveToNext()) {
                val databaseId = cursor.getString(MediaStore.MediaColumns._ID)
                val path = cursor.getString(MediaStore.MediaColumns.DATA)
                val date = cursor.getLong(MediaStore.Images.Media.DATE_TAKEN)
                val type = cursor.getInt(MediaStore.Files.FileColumns.MEDIA_TYPE)
                val duration = if (type == MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE) 0 else cursor.getLong(MediaStore.Video.VideoColumns.DURATION)
                val width = cursor.getInt(MediaStore.MediaColumns.WIDTH)
                val height = cursor.getInt(MediaStore.MediaColumns.HEIGHT)
                val displayName = cursor.getString(MediaStore.Images.Media.DISPLAY_NAME)

                val dbAsset = AssetEntity(databaseId, path, duration, date, width, height, DBUtils.getMediaType(type), displayName)
                cacheContainer.putAsset(dbAsset)

                cursor.close()
                return dbAsset
            } else {
                cursor.close()
                return null
            }
        }
        return null
    }

    @SuppressLint("Recycle")
    override fun getGalleryEntity(context: Context, galleryId: String, type: Int, timeStamp: Long): GalleryEntity? {
        val uri = DBUtils.allUri
        val projection = IDBUtils.storeBucketKeys

        val isAll = galleryId == ""

        val args = ArrayList<String>()
        val typeSelection: String

        when (type) {
            1 -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
                args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString())
            }
            2 -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
                args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString())
            }
            else -> {
                typeSelection = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} in (?,?)"
                args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString())
                args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString())
            }
        }

        val dateSelection = "AND ${MediaStore.MediaColumns.DATE_ADDED} <= ?"
        args.add(timeStamp.toString())

        val idSelection: String
        if (isAll) {
            idSelection = ""
        } else {
            idSelection = "AND ${MediaStore.Images.Media.BUCKET_ID} = ?"
            args.add(galleryId)
        }

        val selection = "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $idSelection"
        val cursor = context.contentResolver.query(uri, projection, selection, args.toTypedArray(), null)
                ?: return null

        val name: String
        if (cursor.moveToNext()) {
            name = cursor.getString(1)
        } else {
            cursor.close()
            return null
        }
        return GalleryEntity(galleryId, name, cursor.count, type, isAll)
    }

    override fun clearCache() {
        cacheContainer.clearCache()
    }

    override fun getFilePath(context: Context, id: String): String? {
        val assetEntity = getAssetEntity(context, id) ?: return null
        val cacheFile = androidQCache.getCacheFile(context, id, assetEntity.displayName)
        return cacheFile.path
    }

    override fun getThumb(context: Context, id: String, width: Int, height: Int): Bitmap? {
        val uri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
//        val original = MediaStore.setRequireOriginal(uri)
        return context.contentResolver.loadThumbnail(uri, Size(width, height), null)
    }

}