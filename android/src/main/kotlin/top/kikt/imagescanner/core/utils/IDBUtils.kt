package top.kikt.imagescanner.core.utils

import android.content.Context
import android.database.Cursor
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.MediaStore.VOLUME_EXTERNAL
import androidx.exifinterface.media.ExifInterface
import top.kikt.imagescanner.core.cache.CacheContainer
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.FilterOptions
import top.kikt.imagescanner.core.entity.GalleryEntity
import java.io.InputStream


/// create 2019-09-11 by cai


interface IDBUtils {

  companion object {
    val isAndroidQ = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

    val storeImageKeys = arrayOf(
        MediaStore.MediaColumns.DISPLAY_NAME, // 显示的名字
        MediaStore.MediaColumns.DATA, // 数据
        MediaStore.MediaColumns._ID, // id
        MediaStore.MediaColumns.TITLE, // id
        MediaStore.MediaColumns.BUCKET_ID, // dir id 目录
        MediaStore.MediaColumns.BUCKET_DISPLAY_NAME, // dir name 目录名字
        MediaStore.MediaColumns.WIDTH, // 宽
        MediaStore.MediaColumns.HEIGHT, // 高
        MediaStore.MediaColumns.DATE_MODIFIED, // 修改时间
        MediaStore.MediaColumns.MIME_TYPE, // 高
        MediaStore.MediaColumns.DATE_TAKEN //日期
    )

    val storeVideoKeys = arrayOf(
        MediaStore.MediaColumns.DISPLAY_NAME, // 显示的名字
        MediaStore.MediaColumns.DATA, // 数据
        MediaStore.MediaColumns._ID, // id
        MediaStore.MediaColumns.TITLE, // id
        MediaStore.MediaColumns.BUCKET_ID, // dir id 目录
        MediaStore.MediaColumns.BUCKET_DISPLAY_NAME, // dir name 目录名字
        MediaStore.MediaColumns.DATE_TAKEN, //日期
        MediaStore.MediaColumns.WIDTH, // 宽
        MediaStore.MediaColumns.HEIGHT, // 高
        MediaStore.MediaColumns.DATE_MODIFIED, // 修改时间
        MediaStore.MediaColumns.MIME_TYPE, // 高
        MediaStore.MediaColumns.DURATION //时长
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

  fun getGalleryList(context: Context, requestType: Int = 0, timeStamp: Long, option: FilterOptions): List<GalleryEntity>

  fun getAssetFromGalleryId(context: Context, galleryId: String, page: Int, pageSize: Int, requestType: Int = 0, timeStamp: Long, option: FilterOptions, cacheContainer: CacheContainer? = null): List<AssetEntity>

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

  fun Cursor.getDouble(columnName: String): Double {
    return getDouble(getColumnIndex(columnName))
  }

  fun getGalleryEntity(context: Context, galleryId: String, type: Int, timeStamp: Long, option: FilterOptions): GalleryEntity?

  fun clearCache()

  fun getFilePath(context: Context, id: String, origin: Boolean): String?

  fun getThumb(context: Context, id: String, width: Int, height: Int, type: Int?): Bitmap?

  fun getAssetFromGalleryIdRange(context: Context, gId: String, start: Int, end: Int, requestType: Int, timestamp: Long, option: FilterOptions): List<AssetEntity>

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

  fun exists(context: Context, id: String): Boolean {
    val columns = arrayOf(MediaStore.Files.FileColumns._ID)
    context.contentResolver.query(DBUtils.allUri, columns, "MediaStore.Files.FileColumns._ID = ?", arrayOf(id), null).use {
      if (it == null) {
        return false
      }
      return it.count >= 1
    }
  }

  fun getExif(context: Context, id: String): ExifInterface?

  fun getOriginBytes(context: Context, asset: AssetEntity): ByteArray

  fun cacheOriginFile(context: Context, asset: AssetEntity, byteArray: ByteArray)

  fun getCondFromType(type: Int, filterOptions: FilterOptions, args: ArrayList<String>): String {
    var condString = ""

    val sizeCond = filterOptions.sizeCond()
    val sizeArgs = filterOptions.sizeArgs()
    val durationCond = filterOptions.durationCond()
    val durationArgs = filterOptions.durationArgs()

    val typeKey = MediaStore.Files.FileColumns.MEDIA_TYPE

    when (type) {
      1 -> {
        condString = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
        args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString())

        condString += "AND $sizeCond"
        args.addAll(sizeArgs)
      }
      2 -> {
        condString = "AND ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
        args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString())

        condString += "AND $sizeCond"
        args.addAll(sizeArgs)

        condString += "AND $durationCond"
        args.addAll(durationArgs)
      }
      else -> {
        condString = "AND ($typeKey = ? OR ($typeKey = ? AND $durationCond)) AND $sizeCond"
        args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString())
        args.add(MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString())
        args.addAll(durationArgs)
        args.addAll(sizeArgs)
      }
    }

    return condString
  }
}