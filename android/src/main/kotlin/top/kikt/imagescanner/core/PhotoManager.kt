package top.kikt.imagescanner.core

import android.content.Context
import android.os.Build
import android.util.Log
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.FilterOption
import top.kikt.imagescanner.core.entity.GalleryEntity
import top.kikt.imagescanner.core.utils.AndroidQDBUtils
import top.kikt.imagescanner.core.utils.ConvertUtils
import top.kikt.imagescanner.core.utils.DBUtils
import top.kikt.imagescanner.core.utils.IDBUtils
import top.kikt.imagescanner.core.utils.IDBUtils.Companion.isAndroidQ
import top.kikt.imagescanner.thumb.ThumbnailUtil
import top.kikt.imagescanner.util.LogUtils
import top.kikt.imagescanner.util.ResultHandler
import java.io.File

/// create 2019-09-05 by cai
/// Do some business logic assembly
class PhotoManager(private val context: Context) {

  companion object {
    const val ALL_ID = "isAll"
  }

  var useOldApi: Boolean = false

  private val dbUtils: IDBUtils
    get() = if (useOldApi || Build.VERSION.SDK_INT < 29) {
      DBUtils
    } else {
      AndroidQDBUtils
    }

  fun getGalleryList(type: Int, timeStamp: Long, hasAll: Boolean, onlyAll: Boolean, option: FilterOption): List<GalleryEntity> {
    if (onlyAll) {
      return dbUtils.getOnlyGalleryList(context, type, timeStamp, option)
    }

    val fromDb = dbUtils.getGalleryList(context, type, timeStamp, option)

    if (!hasAll) {
      return fromDb
    }

    // make is all to the gallery list
    val entity = fromDb.run {
      var count = 0
      for (item in this) {
        count += item.length
      }
      GalleryEntity(ALL_ID, "Recent", count, type, true)
    }

    return listOf(entity) + fromDb
  }

  fun getAssetList(galleryId: String, page: Int, pageCount: Int, typeInt: Int = 0, timestamp: Long, option: FilterOption): List<AssetEntity> {
    val gId = if (galleryId == ALL_ID) "" else galleryId
    return dbUtils.getAssetFromGalleryId(context, gId, page, pageCount, typeInt, timestamp, option)
  }


  fun getAssetListWithRange(galleryId: String, type: Int, start: Int, end: Int, timestamp: Long, option: FilterOption): List<AssetEntity> {
    val gId = if (galleryId == ALL_ID) "" else galleryId
    return dbUtils.getAssetFromGalleryIdRange(context, gId, start, end, type, timestamp, option)
  }

  fun getThumb(id: String, width: Int, height: Int, format: Int, quality: Int, resultHandler: ResultHandler) {
    try {
      if (!isAndroidQ) {
        val asset = dbUtils.getAssetEntity(context, id)
        if (asset == null) {
          resultHandler.replyError("The asset not found!")
          return
        }
        ThumbnailUtil.getThumbnailByGlide(context, asset.path, width, height, format, quality, resultHandler.result)
      } else {
        // need use android Q  MediaStore thumbnail api

        val asset = dbUtils.getAssetEntity(context, id)
        val type = asset?.type
        val uri = dbUtils.getThumbUri(context, id, width, height, type)
                ?: throw RuntimeException("Cannot load uri of $id.")
        ThumbnailUtil.getThumbOfUri(context, uri, width, height, format, quality) {
          resultHandler.reply(it)
        }
      }
    } catch (e: Exception) {
      Log.e(LogUtils.TAG, "get $id thumb error, width : $width, height: $height", e)
      dbUtils.logRowWithId(context, id)
      resultHandler.replyError("201", "get thumb error", e)
    }
  }

  fun getOriginBytes(id: String, cacheOriginBytes: Boolean, haveLocationPermission: Boolean, resultHandler: ResultHandler) {
    val asset = dbUtils.getAssetEntity(context, id)

    if (asset == null) {
      resultHandler.replyError("The asset not found")
      return
    }
    try {
      if (!isAndroidQ) {
        val byteArray = File(asset.path).readBytes()
        resultHandler.reply(byteArray)
      } else {
        val byteArray = dbUtils.getOriginBytes(context, asset, haveLocationPermission)
        resultHandler.reply(byteArray)
        if (cacheOriginBytes) {
          dbUtils.cacheOriginFile(context, asset, byteArray)
        }
      }
    } catch (e: Exception) {
      dbUtils.logRowWithId(context, id)
      resultHandler.replyError("202", "get origin Bytes error", e)
    }
  }

  fun clearCache() {
    dbUtils.clearCache()
  }

  fun getPathEntity(id: String, type: Int, timestamp: Long, option: FilterOption): GalleryEntity? {
    if (id == ALL_ID) {
      val allGalleryList = dbUtils.getGalleryList(context, type, timestamp, option)
      return if (allGalleryList.isEmpty()) {
        null
      } else {
        // make is all to the gallery list
        allGalleryList.run {
          var count = 0
          for (item in this) {
            count += item.length
          }
          GalleryEntity(ALL_ID, "Recent", count, type, true)
        }
      }
    }
    return dbUtils.getGalleryEntity(context, id, type, timestamp, option)
  }

  fun getFile(id: String, isOrigin: Boolean, resultHandler: ResultHandler) {
    val path = dbUtils.getFilePath(context, id, isOrigin)
    resultHandler.reply(path)
  }

  fun deleteAssetWithIds(ids: List<String>): List<String> {
    return dbUtils.deleteWithIds(context, ids)
  }

  fun saveImage(image: ByteArray, title: String, description: String): AssetEntity? {
    return dbUtils.saveImage(context, image, title, description)
  }

  fun saveImage(path: String, title: String, description: String): AssetEntity? {
    return dbUtils.saveImage(context, path, title, description)
  }

  fun saveVideo(path: String, title: String, desc: String): AssetEntity? {
    if (!File(path).exists()) {
      return null
    }
    return dbUtils.saveVideo(context, path, title, desc)
  }

  fun assetExists(id: String, resultHandler: ResultHandler) {
    val exists: Boolean = dbUtils.exists(context, id)
    resultHandler.reply(exists)
  }

  fun getLocation(id: String): Map<String, Double> {
    val exifInfo = dbUtils.getExif(context, id)
    val latLong = exifInfo?.latLong
    return if (latLong == null) {
      mapOf(
              "lat" to 0.0,
              "lng" to 0.0
      )
    } else {
      mapOf(
              "lat" to latLong[0],
              "lng" to latLong[1]
      )
    }
  }

  fun getMediaUri(id: String, type: Int): String {
    return dbUtils.getMediaUri(context, id, type)
  }

  fun copyToGallery(assetId: String, galleryId: String, resultHandler: ResultHandler) {
    try {
      val assetEntity = dbUtils.copyToGallery(context, assetId, galleryId)
      if (assetEntity == null) {
        resultHandler.reply(null)
        return
      }
      resultHandler.reply(ConvertUtils.convertToAssetResult(assetEntity))
    } catch (e: Exception) {
      LogUtils.error(e)
      resultHandler.reply(null)
    }
  }

  fun moveToGallery(assetId: String, albumId: String, resultHandler: ResultHandler) {
    try {
      val assetEntity = dbUtils.moveToGallery(context, assetId, albumId)
      if (assetEntity == null) {
        resultHandler.reply(null)
        return
      }
      resultHandler.reply(ConvertUtils.convertToAssetResult(assetEntity))
    } catch (e: Exception) {
      LogUtils.error(e)
      resultHandler.reply(null)
    }
  }

  fun removeAllExistsAssets(resultHandler: ResultHandler) {
    val result = dbUtils.removeAllExistsAssets(context)
    resultHandler.reply(result)
  }

  fun getAssetProperties(id: String): AssetEntity? {
    return dbUtils.getAssetEntity(context, id)
  }

  fun getFileSize(assetId: String, resultHandler: ResultHandler) {
    resultHandler.reply(dbUtils.fileSize(context, assetId))
  }

}