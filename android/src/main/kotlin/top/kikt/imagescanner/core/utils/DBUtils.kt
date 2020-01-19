package top.kikt.imagescanner.core.utils

import android.annotation.SuppressLint
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.MediaStore
import android.provider.MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
import android.provider.MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
import androidx.exifinterface.media.ExifInterface
import top.kikt.imagescanner.core.cache.CacheContainer
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.FilterOptions
import top.kikt.imagescanner.core.entity.GalleryEntity
import top.kikt.imagescanner.core.utils.IDBUtils.Companion.storeBucketKeys
import top.kikt.imagescanner.core.utils.IDBUtils.Companion.storeImageKeys
import top.kikt.imagescanner.core.utils.IDBUtils.Companion.storeVideoKeys
import top.kikt.imagescanner.core.utils.IDBUtils.Companion.typeKeys
import java.io.File
import java.io.InputStream
import java.net.URLConnection


/// create 2019-09-05 by cai
/// Call the MediaStore API and get entity for the data.
@Suppress("DEPRECATION")
object DBUtils : IDBUtils {

  private const val TAG = "DBUtils"

  private val imageUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
  private val videoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI

  private val cacheContainer = CacheContainer()

  private val locationKeys = arrayOf(
      MediaStore.Images.ImageColumns.LONGITUDE,
      MediaStore.Images.ImageColumns.LATITUDE
  )

  private fun convertTypeToUri(type: Int): Uri {
    return when (type) {
      1 -> imageUri
      2 -> videoUri
      else -> allUri
    }
  }

  @SuppressLint("Recycle")
  override fun getGalleryList(context: Context, requestType: Int, timeStamp: Long, option: FilterOptions): List<GalleryEntity> {
    val list = ArrayList<GalleryEntity>()
    val uri = allUri
    val projection = storeBucketKeys + arrayOf("count(1)")

    val args = ArrayList<String>()
    val typeSelection: String = getCondFromType(requestType, option, args)

    val dateSelection = "AND ${MediaStore.Images.Media.DATE_TAKEN} <= ?"
    args.add(timeStamp.toString())

    val sizeWhere = AndroidQDBUtils.sizeWhere(requestType)

    val selection = "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere) GROUP BY (${MediaStore.Images.Media.BUCKET_ID}"
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

  override fun getGalleryEntity(context: Context, galleryId: String, type: Int, timeStamp: Long, option: FilterOptions): GalleryEntity? {
    val uri = allUri
    val projection = storeBucketKeys + arrayOf("count(1)")

    val args = ArrayList<String>()
    val typeSelection: String = getCondFromType(type, option, args)

    val dateSelection = "AND ${MediaStore.Images.Media.DATE_TAKEN} <= ?"
    args.add(timeStamp.toString())

    val idSelection: String
    if (galleryId == "") {
      idSelection = ""
    } else {
      idSelection = "AND ${MediaStore.Images.Media.BUCKET_ID} = ?"
      args.add(galleryId)
    }

    val sizeWhere = AndroidQDBUtils.sizeWhere(null)

    val selection = "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $idSelection $sizeWhere) GROUP BY (${MediaStore.Images.Media.BUCKET_ID}"
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

  override fun getThumb(context: Context, id: String, width: Int, height: Int, type: Int?): Bitmap? {
    TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
  }

  @SuppressLint("Recycle")
  override fun getAssetFromGalleryId(
      context: Context,
      galleryId: String,
      page: Int,
      pageSize: Int,
      requestType: Int,
      timeStamp: Long,
      option: FilterOptions,
      cacheContainer: CacheContainer?
  ): List<AssetEntity> {
    val cache = cacheContainer ?: this.cacheContainer

    val isAll = galleryId.isEmpty()

    val list = ArrayList<AssetEntity>()
    val uri = allUri

    val args = ArrayList<String>()
    if (!isAll) {
      args.add(galleryId)
    }
    val typeSelection = getCondFromType(requestType, option, args)

    val dateSelection = "AND ${MediaStore.Images.Media.DATE_TAKEN} <= ?"
    args.add(timeStamp.toString())

    val sizeWhere = AndroidQDBUtils.sizeWhere(requestType)

    val keys = (storeImageKeys + storeVideoKeys + typeKeys + locationKeys).distinct().toTypedArray()
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
      val modifiedDate = cursor.getLong(MediaStore.MediaColumns.DATE_MODIFIED)
      val type = cursor.getInt(MediaStore.Files.FileColumns.MEDIA_TYPE)
      val duration = if (requestType == 1) 0 else cursor.getLong(MediaStore.Video.VideoColumns.DURATION)
      val width = cursor.getInt(MediaStore.MediaColumns.WIDTH)
      val height = cursor.getInt(MediaStore.MediaColumns.HEIGHT)
      val displayName = File(path).name

      val lat = cursor.getDouble(MediaStore.Images.ImageColumns.LATITUDE)
      val lng = cursor.getDouble(MediaStore.Images.ImageColumns.LONGITUDE)

      val asset = AssetEntity(id, path, duration, date, width, height, getMediaType(type), displayName, modifiedDate)

      if (lat != 0.0) {
        asset.lat = lat
      }
      if (lng != 0.0) {
        asset.lng = lng
      }

      list.add(asset)
      cache.putAsset(asset)
    }

    cursor.close()

    return list
  }

  override fun getAssetFromGalleryIdRange(context: Context, gId: String, start: Int, end: Int, requestType: Int, timestamp: Long, option: FilterOptions): List<AssetEntity> {
    val cache = cacheContainer

    val isAll = gId.isEmpty()

    val list = ArrayList<AssetEntity>()
    val uri = allUri

    val args = ArrayList<String>()
    if (!isAll) {
      args.add(gId)
    }
    val typeSelection = getCondFromType(requestType, option, args)

    val dateSelection = "AND ${MediaStore.Images.Media.DATE_TAKEN} <= ?"
    args.add(timestamp.toString())

    val sizeWhere = AndroidQDBUtils.sizeWhere(requestType)

    val keys = (storeImageKeys + storeVideoKeys + typeKeys + locationKeys).distinct().toTypedArray()
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
      val displayName = File(path).name
      val modifiedDate = cursor.getLong(MediaStore.MediaColumns.DATE_MODIFIED)

      val lat = cursor.getDouble(MediaStore.Images.ImageColumns.LATITUDE)
      val lng = cursor.getDouble(MediaStore.Images.ImageColumns.LONGITUDE)

      val asset = AssetEntity(id, path, duration, date, width, height, getMediaType(type), displayName, modifiedDate)

      if (lat != 0.0) {
        asset.lat = lat
      }
      if (lng != 0.0) {
        asset.lng = lng
      }

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

    val keys = (storeImageKeys + storeVideoKeys + locationKeys + typeKeys).distinct().toTypedArray()

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
      val modifiedDate = cursor.getLong(MediaStore.MediaColumns.DATE_MODIFIED)
      val lat = cursor.getDouble(MediaStore.Images.ImageColumns.LATITUDE)
      val lng = cursor.getDouble(MediaStore.Images.ImageColumns.LONGITUDE)

      val dbAsset = AssetEntity(databaseId, path, duration, date, width, height, getMediaType(type), displayName, modifiedDate)

      if (lat != 0.0) {
        dbAsset.lat = lat
      }
      if (lng != 0.0) {
        dbAsset.lng = lng
      }

      dbAsset.lat = lat
      dbAsset.lng = lng

      cacheContainer.putAsset(dbAsset)

      cursor.close()
      return dbAsset
    } else {
      cursor.close()
      return null
    }
  }

  override fun getOriginBytes(context: Context, asset: AssetEntity): ByteArray {
    TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
  }

  override fun cacheOriginFile(context: Context, asset: AssetEntity, byteArray: ByteArray) {
    TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
  }

  override fun getExif(context: Context, id: String): ExifInterface? {
    val asset = getAssetEntity(context, id) ?: return null
    return ExifInterface(asset.path)
  }

  override fun getFilePath(context: Context, id: String, origin: Boolean): String? {
    val assetEntity = getAssetEntity(context, id) ?: return null
    return assetEntity.path
  }

  override fun clearCache() {
    cacheContainer.clearCache()
  }

  override fun saveImage(context: Context, image: ByteArray, title: String, desc: String): AssetEntity? {
    val bmp = BitmapFactory.decodeByteArray(image, 0, image.count())
    val insertImage = MediaStore.Images.Media.insertImage(context.contentResolver, bmp, title, desc)
    val id = ContentUris.parseId(Uri.parse(insertImage))
    return getAssetEntity(context, id.toString())
  }

  override fun saveVideo(context: Context, inputStream: InputStream, title: String, desc: String): AssetEntity? {
    val cr = context.contentResolver
    val timestamp = System.currentTimeMillis() / 1000

    var typeFromStream: String? = URLConnection.guessContentTypeFromStream(inputStream)

    if (typeFromStream == null) {
      typeFromStream = "video/${File(title).extension}"
    }

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