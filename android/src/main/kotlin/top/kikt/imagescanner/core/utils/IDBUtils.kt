package top.kikt.imagescanner.core.utils

import android.annotation.SuppressLint
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.MediaStore.Files.FileColumns.*
import android.provider.MediaStore.VOLUME_EXTERNAL
import androidx.exifinterface.media.ExifInterface
import top.kikt.imagescanner.core.cache.CacheContainer
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.FilterOption
import top.kikt.imagescanner.core.entity.GalleryEntity
import top.kikt.imagescanner.util.LogUtils


/// create 2019-09-11 by cai
@Suppress("DEPRECATION")
@SuppressLint("InlinedApi")
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
            MediaStore.MediaColumns.ORIENTATION, // 角度
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
            MediaStore.MediaColumns.ORIENTATION, // 角度
            MediaStore.MediaColumns.DATE_MODIFIED, // 修改时间
            MediaStore.MediaColumns.MIME_TYPE, // 高
            MediaStore.MediaColumns.DURATION //时长
    )

    val typeKeys = arrayOf(
            MEDIA_TYPE,
            MediaStore.Images.Media.DISPLAY_NAME
    )

    val storeBucketKeys = arrayOf(
            MediaStore.Images.Media.BUCKET_ID,
            MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME
    )

    //    fun galleryIdKey(@MediaTypeDef mediaType: Int) :String{
//      if(mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO)
//        return MediaStore.Audio.AudioColumns.ALBUM
//    }
    val allUri: Uri
      get() = MediaStore.Files.getContentUri(VOLUME_EXTERNAL)

  }

  val idSelection: String
    get() = "${MediaStore.Images.Media._ID} = ?"

  val allUri: Uri
    get() = IDBUtils.allUri

  private val typeUtils: RequestTypeUtils
    get() = RequestTypeUtils

  fun getGalleryList(context: Context, requestType: Int = 0, timeStamp: Long, option: FilterOption): List<GalleryEntity>

  fun getAssetFromGalleryId(context: Context, galleryId: String, page: Int, pageSize: Int, requestType: Int = 0, timeStamp: Long, option: FilterOption, cacheContainer: CacheContainer? = null): List<AssetEntity>

  fun getAssetEntity(context: Context, id: String): AssetEntity?

  fun getMediaType(type: Int): Int {
    return when (type) {
      MEDIA_TYPE_IMAGE -> 1
      MEDIA_TYPE_VIDEO -> 2
      MEDIA_TYPE_AUDIO -> 3
      else -> 0
    }
  }


  fun convertTypeToMediaType(type: Int): Int {
    return when (type) {
      1 -> MEDIA_TYPE_IMAGE
      2 -> MEDIA_TYPE_VIDEO
      3 -> MEDIA_TYPE_AUDIO
      else -> 0
    }
  }

  fun getTypeFromMediaType(mediaType: Int): Int {
    return when (mediaType) {
      MEDIA_TYPE_IMAGE -> 1
      MEDIA_TYPE_VIDEO -> 2
      MEDIA_TYPE_AUDIO -> 3
      else -> 0
    }
  }

  fun Cursor.getInt(columnName: String): Int {
    return getInt(getColumnIndex(columnName))
  }

  fun Cursor.getString(columnName: String): String {
    return getString(getColumnIndex(columnName)) ?: ""
  }

  fun Cursor.getStringOrNull(columnName: String): String? {
    return getString(getColumnIndex(columnName))
  }

  fun Cursor.getLong(columnName: String): Long {
    return getLong(getColumnIndex(columnName))
  }

  fun Cursor.getDouble(columnName: String): Double {
    return getDouble(getColumnIndex(columnName))
  }

  fun getGalleryEntity(context: Context, galleryId: String, type: Int, timeStamp: Long, option: FilterOption): GalleryEntity?

  fun clearCache()

  fun getFilePath(context: Context, id: String, origin: Boolean): String?

  fun getThumbUri(context: Context, id: String, width: Int, height: Int, type: Int?): Uri?

  fun getAssetFromGalleryIdRange(context: Context, gId: String, start: Int, end: Int, requestType: Int, timestamp: Long, option: FilterOption): List<AssetEntity>

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

  fun saveImage(context: Context, path: String, title: String, desc: String): AssetEntity?

  fun saveVideo(context: Context, path: String, title: String, desc: String): AssetEntity?

  fun exists(context: Context, id: String): Boolean {
    val columns = arrayOf(_ID)
    context.contentResolver.query(allUri, columns, "$_ID = ?", arrayOf(id), null).use {
      if (it == null) {
        return false
      }
      return it.count >= 1
    }
  }

  fun getExif(context: Context, id: String): ExifInterface?

  fun getOriginBytes(context: Context, asset: AssetEntity, haveLocationPermission: Boolean): ByteArray

  fun cacheOriginFile(context: Context, asset: AssetEntity, byteArray: ByteArray)

  /**
   * Just filter [MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE]
   */
  fun sizeWhere(requestType: Int?, option: FilterOption): String {
    if (option.imageOption.sizeConstraint.ignoreSize) {
      return ""
    }

    if (requestType == null || !typeUtils.containsImage(requestType)) {
      return ""
    }
    val mediaType = MEDIA_TYPE


    var result = ""

    if (typeUtils.containsVideo(requestType)) {
      result = "OR ( $mediaType = $MEDIA_TYPE_VIDEO )"
    }

    if (typeUtils.containsAudio(requestType)) {
      result = "$result OR ( $mediaType = $MEDIA_TYPE_AUDIO )"
    }

    val size = "${MediaStore.MediaColumns.WIDTH} > 0 AND ${MediaStore.MediaColumns.HEIGHT} > 0"

    val imageCondString = "( $mediaType = $MEDIA_TYPE_IMAGE AND $size )"

    result = "AND ($imageCondString $result)"

    return result
  }

  fun getCondFromType(type: Int, filterOption: FilterOption, args: ArrayList<String>): String {
    val cond = StringBuilder()
    val typeKey = MEDIA_TYPE

    val haveImage = RequestTypeUtils.containsImage(type)
    val haveVideo = RequestTypeUtils.containsVideo(type)
    val haveAudio = RequestTypeUtils.containsAudio(type)

    var imageCondString = ""
    var videoCondString = ""
    var audioCondString = ""

    if (haveImage) {
      val imageCond = filterOption.imageOption
      imageCondString = "$typeKey = ? "
      args.add(MEDIA_TYPE_IMAGE.toString())

      if (!imageCond.sizeConstraint.ignoreSize) {
        val sizeCond = imageCond.sizeCond()
        val sizeArgs = imageCond.sizeArgs()
        imageCondString = "$imageCondString AND $sizeCond"
        args.addAll(sizeArgs)
      }
    }

    if (haveVideo) {
      val videoCond = filterOption.videoOption
      val durationCond = videoCond.durationCond()
      val durationArgs = videoCond.durationArgs()
      videoCondString = "$typeKey = ? AND $durationCond"
      args.add(MEDIA_TYPE_VIDEO.toString())
      args.addAll(durationArgs)
    }

    if (haveAudio) {
      val audioCond = filterOption.audioOption
      val durationCond = audioCond.durationCond()
      val durationArgs = audioCond.durationArgs()
      audioCondString = "$typeKey = ? AND $durationCond"
      args.add(MEDIA_TYPE_AUDIO.toString())
      args.addAll(durationArgs)
    }

    if (haveImage) {
      cond.append("( $imageCondString )")
    }

    if (haveVideo) {
      if (cond.isNotEmpty()) {
        cond.append("OR ")
      }

      cond.append("( $videoCondString )")
    }


    if (haveAudio) {
      if (cond.isNotEmpty()) {
        cond.append("OR ")
      }

      cond.append("( $audioCondString )")
    }

    return "AND ( $cond )"
  }

  fun logRowWithId(context: Context, id: String) {
    if (LogUtils.isLog) {
      val splitter = "".padStart(40, '-')
      LogUtils.info("log error row $id start $splitter")
      val cursor = context.contentResolver.query(allUri, null, "$_ID = ?", arrayOf(id), null)
      cursor?.use {
        val names = it.columnNames
        if (cursor.moveToNext()) {
          for (i in 0 until names.count()) {
            LogUtils.info("${names[i]} : ${cursor.getString(i)}")
          }
        }
      }
      LogUtils.info("log error row $id end $splitter")
    }
  }

  fun getMediaUri(context: Context, id: String, type: Int): String

  fun getOnlyGalleryList(context: Context, requestType: Int, timeStamp: Long, option: FilterOption): List<GalleryEntity>

  fun getDateCond(args: ArrayList<String>, timestamp: Long, option: FilterOption): String {
    val minMs = option.dateCond.minMs
    val maxMs = option.dateCond.maxMs

    val dateSelection = "AND ( ${MediaStore.Images.Media.DATE_ADDED} >= ? AND ${MediaStore.Images.Media.DATE_ADDED} <= ? )"
    args.add((minMs / 1000).toString())
    args.add((maxMs / 1000).toString())
    return dateSelection
  }


  fun getSortOrder(start: Int, pageSize: Int, filterOption: FilterOption): String {
    val asc =
            if (filterOption.dateCond.asc) {
              "ASC"
            } else {
              "DESC"
            }
    return "$DATE_ADDED $asc LIMIT $pageSize OFFSET $start"
  }

  fun copyToGallery(context: Context, assetId: String, galleryId: String): AssetEntity?

  fun moveToGallery(context: Context, assetId: String, galleryId: String): AssetEntity?

  fun getSomeInfo(context: Context, assetId: String): Pair<String, String>?

  fun getInsertUri(mediaType: Int): Uri {
    return when (mediaType) {
      MEDIA_TYPE_AUDIO -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
      MEDIA_TYPE_VIDEO -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
      MEDIA_TYPE_IMAGE -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
      else -> allUri
    }
  }

  fun throwMsg(msg: String): Nothing {
    throw RuntimeException(msg)
  }

  fun removeAllExistsAssets(context: Context): Boolean

  fun fileSize(context: Context, assetId: String) :Long?{
    val asset = getAssetEntity(context,assetId)
    return asset?.size
  }
}