package top.kikt.imagescanner.core.utils

import android.annotation.SuppressLint
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import androidx.annotation.RequiresApi
import androidx.exifinterface.media.ExifInterface
import top.kikt.imagescanner.core.cache.AndroidQCache
import top.kikt.imagescanner.core.cache.CacheContainer
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.FilterOption
import top.kikt.imagescanner.core.entity.GalleryEntity
import top.kikt.imagescanner.util.LogUtils
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.net.URLConnection

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
  override fun getGalleryList(context: Context, requestType: Int, timeStamp: Long, option: FilterOption): List<GalleryEntity> {
    val list = ArrayList<GalleryEntity>()

    val args = ArrayList<String>()
    val typeSelection: String = getCondFromType(requestType, option, args)

    val dateSelection = "AND ${MediaStore.MediaColumns.DATE_ADDED} <= ?"
    args.add(timeStamp.toString())

    val sizeWhere = sizeWhere(requestType)

    val selections = "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"

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
  override fun getAssetFromGalleryId(context: Context, galleryId: String, page: Int, pageSize: Int, requestType: Int, timeStamp: Long, option: FilterOption, cacheContainer: CacheContainer?): List<AssetEntity> {
    val cache = cacheContainer ?: this.cacheContainer

    val isAll = galleryId.isEmpty()

    val list = ArrayList<AssetEntity>()
    val uri = allUri

    val args = ArrayList<String>()
    if (!isAll) {
      args.add(galleryId)
    }
    val typeSelection: String = getCondFromType(requestType, option, args)

    val sizeWhere = sizeWhere(requestType)

    val dateSelection = "AND ${MediaStore.Images.Media.DATE_ADDED} <= ?"
    args.add(timeStamp.toString())

    val keys = (IDBUtils.storeImageKeys + IDBUtils.storeVideoKeys + IDBUtils.typeKeys).distinct().toTypedArray()
    val selection = if (isAll) {
      "${MediaStore.Images.ImageColumns.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"
    } else {
      "${MediaStore.Images.ImageColumns.BUCKET_ID} = ? $typeSelection $dateSelection $sizeWhere"
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
      val modifiedDate = cursor.getLong(MediaStore.MediaColumns.DATE_MODIFIED)

      val asset = AssetEntity(id, path, duration, date, width, height, getMediaType(type), displayName, modifiedDate)
      list.add(asset)
      cache.putAsset(asset)
    }

    cursor.close()

    return list

  }

  override fun getAssetFromGalleryIdRange(context: Context, gId: String, start: Int, end: Int, requestType: Int, timestamp: Long, option: FilterOption): List<AssetEntity> {
    val cache = cacheContainer

    val isAll = gId.isEmpty()

    val list = ArrayList<AssetEntity>()
    val uri = allUri

    val args = ArrayList<String>()
    if (!isAll) {
      args.add(gId)
    }
    val typeSelection: String = getCondFromType(requestType, option, args)

    val sizeWhere = sizeWhere(requestType)

    val dateSelection = "AND ${MediaStore.Images.Media.DATE_ADDED} <= ?"
    args.add(timestamp.toString())

    val keys = (IDBUtils.storeImageKeys + IDBUtils.storeVideoKeys + IDBUtils.typeKeys).distinct().toTypedArray()
    val selection = if (isAll) {
      "${MediaStore.Images.ImageColumns.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"
    } else {
      "${MediaStore.Images.ImageColumns.BUCKET_ID} = ? $typeSelection $dateSelection $sizeWhere"
    }

    val pageSize = end - start

    val sortOrder = "${MediaStore.Images.Media.DATE_TAKEN} DESC LIMIT $pageSize OFFSET $start"
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
      val modifiedDate = cursor.getLong(MediaStore.MediaColumns.DATE_MODIFIED)

      val asset = AssetEntity(id, path, duration, date, width, height, getMediaType(type), displayName, modifiedDate)
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

    val keys = (IDBUtils.storeImageKeys + IDBUtils.typeKeys + IDBUtils.storeVideoKeys).distinct().toTypedArray()

    val selection = "${MediaStore.Files.FileColumns._ID} = ?"

    val args = arrayOf(id)

    val cursor = context.contentResolver.query(allUri, keys, selection, args, null)
    cursor?.use {
      if (cursor.moveToNext()) {
        val databaseId = cursor.getString(MediaStore.MediaColumns._ID)
        val path = cursor.getString(MediaStore.MediaColumns.DATA)
        val date = cursor.getLong(MediaStore.Images.Media.DATE_TAKEN)
        val type = cursor.getInt(MediaStore.Files.FileColumns.MEDIA_TYPE)
        val duration = if (type == MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE) 0 else cursor.getLong(MediaStore.Video.VideoColumns.DURATION)
        val width = cursor.getInt(MediaStore.MediaColumns.WIDTH)
        val height = cursor.getInt(MediaStore.MediaColumns.HEIGHT)
        val displayName = cursor.getString(MediaStore.MediaColumns.DISPLAY_NAME)
        val modifiedDate = cursor.getLong(MediaStore.MediaColumns.DATE_MODIFIED)

        val dbAsset = AssetEntity(databaseId, path, duration, date, width, height, getMediaType(type), displayName, modifiedDate)
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
  override fun getGalleryEntity(context: Context, galleryId: String, type: Int, timeStamp: Long, option: FilterOption): GalleryEntity? {
    val uri = allUri
    val projection = IDBUtils.storeBucketKeys

    val isAll = galleryId == ""

    val args = ArrayList<String>()
    val typeSelection: String = getCondFromType(type, option, args)

    val dateSelection = "AND ${MediaStore.MediaColumns.DATE_ADDED} <= ?"
    args.add(timeStamp.toString())

    val idSelection: String
    if (isAll) {
      idSelection = ""
    } else {
      idSelection = "AND ${MediaStore.Images.Media.BUCKET_ID} = ?"
      args.add(galleryId)
    }

    val sizeWhere = sizeWhere(null)

    val selection = "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $idSelection $sizeWhere"
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

  override fun getExif(context: Context, id: String): ExifInterface? {
    try {
      val asset = getAssetEntity(context, id) ?: return null

      val uri =
              if (asset.type == 1)
                Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, asset.id)
              else
                Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, asset.id)

      val originalUri = MediaStore.setRequireOriginal(uri)

      val inputStream = context.contentResolver.openInputStream(originalUri) ?: return null
      return ExifInterface(inputStream)
    } catch (e: Exception) {
      return null
    }
  }

  override fun clearCache() {
    cacheContainer.clearCache()
  }

  override fun getFilePath(context: Context, id: String, origin: Boolean): String? {
    val assetEntity = getAssetEntity(context, id) ?: return null
    val cacheFile = androidQCache.getCacheFile(context, id, assetEntity.displayName, assetEntity.type, origin)
    return cacheFile.path
  }

  override fun getThumb(context: Context, id: String, width: Int, height: Int, type: Int?): Bitmap? {
    if (type == null) {
      return null
    }
    val uri = getUri(id, type)
    return context.contentResolver.loadThumbnail(uri, Size(width, height), null)
  }

  private fun getUri(asset: AssetEntity, isOrigin: Boolean = false): Uri = getUri(asset.id, asset.type, isOrigin)

  private fun getUri(id: String, type: Int, isOrigin: Boolean = false): Uri {
    var uri =
            if (type == 1)
              Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
            else
              Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id)

    if (isOrigin) {
      uri = MediaStore.setRequireOriginal(uri)
    }
    return uri
  }

  override fun getOriginBytes(context: Context, asset: AssetEntity, haveLocationPermission: Boolean): ByteArray {
    val file = androidQCache.getCacheFile(context, asset.id, asset.displayName, true)
    if (file.exists()) {
      LogUtils.info("the origin bytes come from ${file.absolutePath}")
      return file.readBytes()
    }

    val uri = getUri(asset, haveLocationPermission)
    val inputStream = context.contentResolver.openInputStream(uri)

    LogUtils.info("the cache file no exists, will read from MediaStore: $uri")

    val outputStream = ByteArrayOutputStream()
    inputStream?.use {
      outputStream.write(it.readBytes())
    }
    val byteArray = outputStream.toByteArray()

    if (LogUtils.isLog) {
      LogUtils.info("The asset ${asset.id} origin byte length : ${byteArray.count()}")
    }

    return byteArray
  }

  override fun cacheOriginFile(context: Context, asset: AssetEntity, byteArray: ByteArray) {
    androidQCache.saveAssetCache(context, asset, byteArray, true)
  }

  override fun saveImage(context: Context, image: ByteArray, title: String, desc: String): AssetEntity? {
    val inputStream = ByteArrayInputStream(image)

    val cr = context.contentResolver
    val timestamp = System.currentTimeMillis() / 1000

    val typeFromStream = URLConnection.guessContentTypeFromStream(inputStream)

    val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI

    val values = ContentValues().apply {
      put(MediaStore.MediaColumns.DISPLAY_NAME, title)
      put(MediaStore.Images.ImageColumns.MIME_TYPE, typeFromStream)
      put(MediaStore.Images.ImageColumns.TITLE, title)
      put(MediaStore.Images.ImageColumns.DESCRIPTION, desc)
      put(MediaStore.Images.ImageColumns.DATE_ADDED, timestamp)
      put(MediaStore.Images.ImageColumns.DATE_MODIFIED, timestamp)
    }

    val contentUri = cr.insert(uri, values) ?: return null
    val outputStream = cr.openOutputStream(contentUri)

    outputStream?.use {
      inputStream.use {
        inputStream.copyTo(outputStream)
      }
    }

    val id = ContentUris.parseId(contentUri)

    cr.notifyChange(contentUri, null)
    return getAssetEntity(context, id.toString())
  }

  override fun saveVideo(context: Context, inputStream: InputStream, title: String, desc: String): AssetEntity? {
    val cr = context.contentResolver
    val timestamp = System.currentTimeMillis() / 1000

    val typeFromStream = URLConnection.guessContentTypeFromStream(inputStream)

    val uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI

    val values = ContentValues().apply {
      put(MediaStore.MediaColumns.DISPLAY_NAME, title)
      put(MediaStore.Video.VideoColumns.MIME_TYPE, typeFromStream)
      put(MediaStore.Video.VideoColumns.TITLE, title)
      put(MediaStore.Video.VideoColumns.DESCRIPTION, desc)
      put(MediaStore.Video.VideoColumns.DATE_ADDED, timestamp)
      put(MediaStore.Video.VideoColumns.DATE_MODIFIED, timestamp)
    }

    val contentUri = cr.insert(uri, values) ?: return null
    val outputStream = cr.openOutputStream(contentUri)

    outputStream?.use {
      inputStream.use {
        inputStream.copyTo(outputStream)
      }
    }

    val id = ContentUris.parseId(contentUri)

    cr.notifyChange(contentUri, null)
    return getAssetEntity(context, id.toString())
  }

}