package top.kikt.imagescanner.core.utils

import android.annotation.SuppressLint
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import androidx.exifinterface.media.ExifInterface
import top.kikt.imagescanner.core.PhotoManager
import top.kikt.imagescanner.core.cache.AndroidQCache
import top.kikt.imagescanner.core.cache.CacheContainer
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.FilterOption
import top.kikt.imagescanner.core.entity.GalleryEntity
import top.kikt.imagescanner.util.LogUtils
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
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
    
    val dateSelection = getDateCond(args, timeStamp, option)
    
    val sizeWhere = sizeWhere(requestType, option)
    
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
      val galleryName = cursor.getString(1) ?: ""
      
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
  
  override fun getOnlyGalleryList(context: Context, requestType: Int, timeStamp: Long, option: FilterOption): List<GalleryEntity> {
    val list = ArrayList<GalleryEntity>()
    
    val args = ArrayList<String>()
    val typeSelection: String = getCondFromType(requestType, option, args)
    
    val dateSelection = getDateCond(args, timeStamp, option)
    
    val sizeWhere = sizeWhere(requestType, option)
    
    val selections = "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"
    
    val cursor = context.contentResolver.query(allUri, galleryKeys, selections, args.toTypedArray(), null)
      ?: return list
    
    cursor.use {
      val count = cursor.count
      val galleryEntity = GalleryEntity(PhotoManager.ALL_ID, "Recent", count, requestType, true)
      list.add(galleryEntity)
    }
    
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
    
    val sizeWhere = sizeWhere(requestType, option)
    
    val dateSelection = getDateCond(args, timeStamp, option)
    
    val keys = (IDBUtils.storeImageKeys + IDBUtils.storeVideoKeys + IDBUtils.typeKeys).distinct().toTypedArray()
    val selection = if (isAll) {
      "${MediaStore.Images.ImageColumns.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"
    } else {
      "${MediaStore.Images.ImageColumns.BUCKET_ID} = ? $typeSelection $dateSelection $sizeWhere"
    }
    
    val sortOrder = getSortOrder(page * pageSize, pageSize, option)
    val cursor = context.contentResolver.query(uri, keys, selection, args.toTypedArray(), sortOrder)
      ?: return emptyList()
    
    while (cursor.moveToNext()) {
      val asset = convertCursorToAssetEntity(cursor, requestType)
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
    
    val sizeWhere = sizeWhere(requestType, option)
    
    val dateSelection = getDateCond(args, timestamp, option)
    
    val keys = (IDBUtils.storeImageKeys + IDBUtils.storeVideoKeys + IDBUtils.typeKeys).distinct().toTypedArray()
    val selection = if (isAll) {
      "${MediaStore.Images.ImageColumns.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $sizeWhere"
    } else {
      "${MediaStore.Images.ImageColumns.BUCKET_ID} = ? $typeSelection $dateSelection $sizeWhere"
    }
    
    val pageSize = end - start
    
    val sortOrder = getSortOrder(start, pageSize, option)
    val cursor = context.contentResolver.query(uri, keys, selection, args.toTypedArray(), sortOrder)
      ?: return emptyList()
    
    while (cursor.moveToNext()) {
      val asset = convertCursorToAssetEntity(cursor, requestType)
      list.add(asset)
      cache.putAsset(asset)
    }
    
    cursor.close()
    
    return list
    
  }
  
  private fun convertCursorToAssetEntity(cursor: Cursor, requestType: Int): AssetEntity {
    val id = cursor.getString(MediaStore.MediaColumns._ID)
    val path = cursor.getString(MediaStore.MediaColumns.DATA)
    val date = cursor.getLong(MediaStore.Images.Media.DATE_TAKEN)
    val type = cursor.getInt(MediaStore.Files.FileColumns.MEDIA_TYPE)
    
    val duration = if (type == MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE) 0 else cursor.getLong(MediaStore.Video.VideoColumns.DURATION)
    val width = cursor.getInt(MediaStore.MediaColumns.WIDTH)
    val height = cursor.getInt(MediaStore.MediaColumns.HEIGHT)
    val displayName = cursor.getString(MediaStore.Images.Media.DISPLAY_NAME)
    val modifiedDate = cursor.getLong(MediaStore.MediaColumns.DATE_MODIFIED)
    val orientation: Int = cursor.getInt(MediaStore.MediaColumns.ORIENTATION)
    return AssetEntity(id, path, duration, date, width, height, getMediaType(type), displayName, modifiedDate, orientation)
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
        val type = cursor.getInt(MediaStore.Files.FileColumns.MEDIA_TYPE)
        val dbAsset = convertCursorToAssetEntity(cursor, type)
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
    
    val dateSelection = getDateCond(args, timeStamp, option)
    
    val idSelection: String
    if (isAll) {
      idSelection = ""
    } else {
      idSelection = "AND ${MediaStore.Images.Media.BUCKET_ID} = ?"
      args.add(galleryId)
    }
    
    val sizeWhere = sizeWhere(null, option)
    
    val selection = "${MediaStore.Images.Media.BUCKET_ID} IS NOT NULL $typeSelection $dateSelection $idSelection $sizeWhere"
    val cursor = context.contentResolver.query(uri, projection, selection, args.toTypedArray(), null)
      ?: return null
    
    val name: String?
    if (cursor.moveToNext()) {
      name = cursor.getString(1) ?: ""
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
  
  override fun getThumbUri(context: Context, id: String, width: Int, height: Int, type: Int?): Uri? {
    if (type == null) {
      return null
    }
    return getUri(id, type)
  }
  
  private fun getUri(asset: AssetEntity, isOrigin: Boolean = false): Uri = getUri(asset.id, asset.type, isOrigin)
  
  private fun getUri(id: String, type: Int, isOrigin: Boolean = false): Uri {
    var uri =
      when (type) {
        1 -> Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
        2 -> Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id)
        else -> Uri.withAppendedPath(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
      }
    
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
    val (width, height) =
      try {
        val bmp = BitmapFactory.decodeByteArray(image, 0, image.count())
        Pair(bmp.width, bmp.height)
      } catch (e: Exception) {
        Pair(0, 0)
      }
    
    val inputStream = ByteArrayInputStream(image)
    
    val cr = context.contentResolver
    val timestamp = System.currentTimeMillis() / 1000
    
    val typeFromStream = URLConnection.guessContentTypeFromStream(inputStream)
    
    val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
    
    val values = ContentValues().apply {
      put(MediaStore.Files.FileColumns.MEDIA_TYPE, MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE)
      
      put(MediaStore.MediaColumns.DISPLAY_NAME, title)
      put(MediaStore.Images.ImageColumns.MIME_TYPE, typeFromStream)
      put(MediaStore.Images.ImageColumns.TITLE, title)
      put(MediaStore.Images.ImageColumns.DESCRIPTION, desc)
      put(MediaStore.Images.ImageColumns.DATE_ADDED, timestamp)
      put(MediaStore.Images.Media.DISPLAY_NAME, title)
      put(MediaStore.Images.ImageColumns.DATE_MODIFIED, timestamp)
      put(MediaStore.Images.ImageColumns.WIDTH, width)
      put(MediaStore.Images.ImageColumns.HEIGHT, height)
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
  
  override fun saveImage(context: Context, path: String, title: String, desc: String): AssetEntity? {
    val cr = context.contentResolver
    val timestamp = System.currentTimeMillis() / 1000
    val inputStream = FileInputStream(path)
    val typeFromStream = URLConnection.guessContentTypeFromStream(inputStream)
      ?: "image/${File(path).extension}"
    
    val (width, height) =
      try {
        val bmp = BitmapFactory.decodeFile(path)
        Pair(bmp.width, bmp.height)
      } catch (e: Exception) {
        Pair(0, 0)
      }
    
    val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
    
    val values = ContentValues().apply {
      put(MediaStore.Files.FileColumns.MEDIA_TYPE, MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE)
      
      put(MediaStore.MediaColumns.DISPLAY_NAME, title)
      put(MediaStore.Images.ImageColumns.MIME_TYPE, typeFromStream)
      put(MediaStore.Images.ImageColumns.TITLE, title)
      put(MediaStore.Images.ImageColumns.DESCRIPTION, desc)
      put(MediaStore.Images.ImageColumns.DATE_ADDED, timestamp)
      put(MediaStore.Images.ImageColumns.DATE_MODIFIED, timestamp)
      put(MediaStore.Images.ImageColumns.DATE_TAKEN, timestamp * 1000)
      put(MediaStore.Images.ImageColumns.DISPLAY_NAME, title)
      put(MediaStore.Images.ImageColumns.DURATION, 0)
      put(MediaStore.Images.ImageColumns.WIDTH, width)
      put(MediaStore.Images.ImageColumns.HEIGHT, height)
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
  
  override fun copyToGallery(context: Context, assetId: String, galleryId: String): AssetEntity? {
    
    val (currentGalleryId, _) = getSomeInfo(context, assetId)
      ?: throwMsg("Cannot get gallery id of $assetId")
    
    if (galleryId == currentGalleryId) {
      throwMsg("No copy required, because the target gallery is the same as the current one.")
    }
    
    val cr = context.contentResolver
    
    val asset = getAssetEntity(context, assetId)
      ?: throwMsg("No copy required, because the target gallery is the same as the current one.")
    
    val copyKeys = arrayListOf(
      MediaStore.MediaColumns.DISPLAY_NAME,
      MediaStore.Video.VideoColumns.TITLE,
      MediaStore.Video.VideoColumns.DATE_ADDED,
      MediaStore.Video.VideoColumns.DATE_MODIFIED,
      MediaStore.Video.VideoColumns.DATE_TAKEN,
      MediaStore.Video.VideoColumns.DURATION,
      MediaStore.Video.VideoColumns.WIDTH,
      MediaStore.Video.VideoColumns.HEIGHT
    )
    
    val mediaType = convertTypeToMediaType(asset.type)
    
    if (mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) {
      copyKeys.add(MediaStore.Video.VideoColumns.DESCRIPTION)
    }
    
    val cursor = cr.query(allUri, copyKeys.toTypedArray() + arrayOf(MediaStore.Video.VideoColumns.RELATIVE_PATH), idSelection, arrayOf(assetId), null)
      ?: throwMsg("Cannot find asset.")
    
    if (!cursor.moveToNext()) {
      throwMsg("Cannot find asset.")
    }
    
    val insertUri = getInsertUri(mediaType)
    
    val relativePath = getRelativePath(context, galleryId)
    
    val cv = ContentValues().apply {
      for (key in copyKeys) {
        put(key, cursor.getString(key))
      }
      put(MediaStore.Files.FileColumns.MEDIA_TYPE, mediaType)
      put(MediaStore.Files.FileColumns.RELATIVE_PATH, relativePath)
    }
    
    val insertedUri = cr.insert(insertUri, cv) ?: throwMsg("Cannot insert new asset.")
    val outputStream = cr.openOutputStream(insertedUri)
      ?: throwMsg("Cannot open output stream for $insertedUri.")
    val inputUri = getUri(asset, true)
    val inputStream = cr.openInputStream(inputUri)
      ?: throwMsg("Cannot open input stream for $inputUri")
    inputStream.use {
      outputStream.use {
        inputStream.copyTo(outputStream)
      }
    }
    
    val insertedId = insertedUri.lastPathSegment
      ?: throwMsg("Cannot open output stream for $insertedUri.")
    
    return getAssetEntity(context, insertedId)
  }
  
  override fun moveToGallery(context: Context, assetId: String, galleryId: String): AssetEntity? {
    
    val (currentGalleryId, _) = getSomeInfo(context, assetId)
      ?: throwMsg("Cannot get gallery id of $assetId")
    
    if (galleryId == currentGalleryId) {
      throwMsg("No move required, because the target gallery is the same as the current one.")
    }
    
    val cr = context.contentResolver
    
    val targetPath = getRelativePath(context, galleryId)
    
    val contentValues = ContentValues().apply {
      put(MediaStore.MediaColumns.RELATIVE_PATH, targetPath)
    }
    
    val count = cr.update(allUri, contentValues, idSelection, arrayOf(assetId))
    if (count > 0) {
      return getAssetEntity(context, assetId)
    }
    throwMsg("Cannot update $assetId relativePath")
  }
  
  private fun getRelativePath(context: Context, galleryId: String): String? {
    val cr = context.contentResolver
    
    val cursor = cr.query(allUri, arrayOf(MediaStore.Files.FileColumns.BUCKET_ID, MediaStore.Files.FileColumns.RELATIVE_PATH), "${MediaStore.Files.FileColumns.BUCKET_ID} = ?", arrayOf(galleryId), null)
      ?: return null
    
    cursor.use {
      if (!cursor.moveToNext()) {
        return null
      }
      return cursor.getString(1)
    }
  }
  
  override fun getSomeInfo(context: Context, assetId: String): Pair<String, String>? {
    val cr = context.contentResolver
    
    val cursor = cr.query(allUri, arrayOf(MediaStore.Files.FileColumns.BUCKET_ID, MediaStore.Files.FileColumns.RELATIVE_PATH), "${MediaStore.Files.FileColumns._ID} = ?", arrayOf(assetId), null)
      ?: return null
    
    cursor.use {
      if (!cursor.moveToNext()) {
        return null
      }
      
      val galleryID = cursor.getString(0)
      val path = cursor.getString(1)
      
      return Pair(galleryID, File(path).parent)
    }
  }
  
  override fun saveVideo(context: Context, path: String, title: String, desc: String): AssetEntity? {
    val cr = context.contentResolver
    val timestamp = System.currentTimeMillis() / 1000
    val inputStream = FileInputStream(path)
    val typeFromStream = URLConnection.guessContentTypeFromStream(inputStream)
      ?: "video/${File(path).extension}"
    
    val uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
    
    val info = VideoUtils.getPropertiesUseMediaPlayer(path)
    
    val values = ContentValues().apply {
      put(MediaStore.Files.FileColumns.MEDIA_TYPE, MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO)
      
      put(MediaStore.MediaColumns.DISPLAY_NAME, title)
      put(MediaStore.Video.VideoColumns.MIME_TYPE, typeFromStream)
      put(MediaStore.Video.VideoColumns.TITLE, title)
      put(MediaStore.Video.VideoColumns.DESCRIPTION, desc)
      put(MediaStore.Video.VideoColumns.DATE_ADDED, timestamp)
      put(MediaStore.Video.VideoColumns.DATE_MODIFIED, timestamp)
      put(MediaStore.Video.VideoColumns.DATE_TAKEN, timestamp * 1000)
      put(MediaStore.Video.VideoColumns.DISPLAY_NAME, title)
      put(MediaStore.Video.VideoColumns.DURATION, info.duration)
      put(MediaStore.Video.VideoColumns.WIDTH, info.width)
      put(MediaStore.Video.VideoColumns.HEIGHT, info.height)
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
  
  override fun getMediaUri(context: Context, id: String, type: Int): String {
    val uri = getUri(id, type, false)
    return uri.toString()
  }
}