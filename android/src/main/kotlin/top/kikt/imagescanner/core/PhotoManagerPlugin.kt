package top.kikt.imagescanner.core

import android.Manifest
import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Handler
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import top.kikt.imagescanner.core.entity.AssetEntity
import top.kikt.imagescanner.core.entity.FilterOption
import top.kikt.imagescanner.core.utils.ConvertUtils
import top.kikt.imagescanner.permission.PermissionsListener
import top.kikt.imagescanner.permission.PermissionsUtils
import top.kikt.imagescanner.util.LogUtils
import top.kikt.imagescanner.util.ResultHandler
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit

/// create 2019-09-05 by cai


class PhotoManagerPlugin(
        private val applicationContext: Context,
        private val messenger: BinaryMessenger,
        var activity: Activity?,
        private val permissionsUtils: PermissionsUtils
) : MethodChannel.MethodCallHandler {

  companion object {
    private const val poolSize = 8
    private val threadPool: ThreadPoolExecutor = ThreadPoolExecutor(
            poolSize + 3,
            1000,
            200,
            TimeUnit.MINUTES,
            ArrayBlockingQueue<Runnable>(poolSize + 3)
    )

    fun runOnBackground(runnable: () -> Unit) {
      threadPool.execute(runnable)
    }

    var cacheOriginBytes = true
  }

  private val notifyChannel = PhotoManagerNotifyChannel(applicationContext, messenger, Handler())

  init {
    permissionsUtils.permissionsListener = object : PermissionsListener {
      override fun onDenied(deniedPermissions: MutableList<String>, grantedPermissions: MutableList<String>) {
      }

      override fun onGranted() {
      }
    }
  }

  private val photoManager = PhotoManager(applicationContext)

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val resultHandler = ResultHandler(result)

    var needLocationPermissions = false

    val handleResult = when (call.method) {
      "releaseMemCache" -> {
        photoManager.clearCache()
        true
      }
      "log" -> {
        LogUtils.isLog = call.arguments()
        true
      }
      "openSetting" -> {
        permissionsUtils.getAppDetailSettingIntent(activity)
        true
      }
      "forceOldApi" -> {
        photoManager.useOldApi = true
        resultHandler.reply(1)
        true
      }
      "systemVersion" -> {
        resultHandler.reply(Build.VERSION.SDK_INT.toString())
        true
      }
      "cacheOriginBytes" -> {
        val cacheOriginBytes = call.arguments<Boolean>()
        PhotoManagerPlugin.cacheOriginBytes = cacheOriginBytes
        resultHandler.reply(cacheOriginBytes)
        true
      }
      "getLatLngAndroidQ" -> {
        /// 这里不拦截, 然后额外添加gps权限
        needLocationPermissions = true
        false
      }
      "copyAsset" -> {
        needLocationPermissions = true
        false
      }
      "getFullFile" -> {
        val isOrigin = call.argument<Boolean>("isOrigin")!!
        if (isOrigin && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          needLocationPermissions = true
        }
        false
      }
      "getOriginBytes" -> {
        needLocationPermissions = true
        false
      }
      "getMediaUrl" -> {
        false
      }
      "getFileSize" -> {
        false
      }
      else -> false
    }

    if (handleResult) {
      return
    }

    val utils = permissionsUtils.apply {
      withActivity(activity)
      permissionsListener = object : PermissionsListener {
        override fun onDenied(deniedPermissions: MutableList<String>, grantedPermissions: MutableList<String>) {
          LogUtils.info("onDenied call.method = ${call.method}")
          if (call.method == "requestPermission") {
            resultHandler.reply(0)
          } else {
            if (grantedPermissions.containsAll(arrayListOf(Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE))) {
              onHandlePermissionResult(call, resultHandler, false)
            } else {
              replyPermissionError(resultHandler)
            }
          }
        }

        override fun onGranted() {
          onHandlePermissionResult(call, resultHandler, true)
        }
      }
    }

    val permissions = arrayListOf(Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE)

    if (needLocationPermissions && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      permissions.add(Manifest.permission.ACCESS_MEDIA_LOCATION)
    }

    utils.getPermissions(activity, 3001, permissions)
  }

  private fun replyPermissionError(resultHandler: ResultHandler) {
    resultHandler.replyError("Request for permission failed.", "User denied permission.", null)
  }

  private fun onHandlePermissionResult(call: MethodCall, resultHandler: ResultHandler, haveLocationPermission: Boolean) {
    LogUtils.info("onGranted call.method = ${call.method}")
    when (call.method) {
      "requestPermission" -> resultHandler.reply(1)
      "getGalleryList" -> {
        if (Build.VERSION.SDK_INT >= 29) {
          notifyChannel.setAndroidQExperimental(true)
        }
        runOnBackground {
          val type = call.argument<Int>("type")!!
          val timeStamp = getTimeStamp()
          val hasAll = call.argument<Boolean>("hasAll")!!
          val option = call.getOption()
          val onlyAll = call.argument<Boolean>("onlyAll")!!

          val list = photoManager.getGalleryList(type, timeStamp, hasAll, onlyAll, option)
          resultHandler.reply(ConvertUtils.convertToGalleryResult(list))
        }
      }
      "getAssetWithGalleryId" -> {
        runOnBackground {
          val id = call.argument<String>("id")!!
          val page = call.argument<Int>("page")!!
          val pageCount = call.argument<Int>("pageCount")!!
          val type = call.argument<Int>("type")!!
          val timeStamp = getTimeStamp()
          val option = call.getOption()
          val list = photoManager.getAssetList(id, page, pageCount, type, timeStamp, option)
          resultHandler.reply(ConvertUtils.convertToAssetResult(list))
        }
      }
      "getAssetListWithRange" -> {
        runOnBackground {
          val galleryId = call.getString("galleryId")
          val type = call.getInt("type")
          val start = call.getInt("start")
          val end = call.getInt("end")
          val timestamp = getTimeStamp()
          val option = call.getOption()
          val list: List<AssetEntity> = photoManager.getAssetListWithRange(galleryId, type, start, end, timestamp, option)
          resultHandler.reply(ConvertUtils.convertToAssetResult(list))
        }
      }
      "getThumb" -> {
        runOnBackground {
          val id = call.argument<String>("id")!!
          val width = call.argument<Int>("width")!!
          val height = call.argument<Int>("height")!!
          val format = call.argument<Int>("format")!!
          val quality = call.argument<Int>("quality")!!
          photoManager.getThumb(id, width, height, format, quality, resultHandler)
        }
      }
      "assetExists" -> {
        runOnBackground {
          val id = call.argument<String>("id")!!
          photoManager.assetExists(id, resultHandler)
        }
      }
      "getFullFile" -> {
        runOnBackground {
          val id = call.argument<String>("id")!!
          val isOrigin = if (!haveLocationPermission) false else call.argument<Boolean>("isOrigin")!!
          photoManager.getFile(id, isOrigin, resultHandler)
        }
      }
      "getOriginBytes" -> {
        runOnBackground {
          val id = call.argument<String>("id")!!
          photoManager.getOriginBytes(id, cacheOriginBytes, haveLocationPermission, resultHandler)
        }
      }
      "getMediaUrl" -> {
        runOnBackground {
          val id = call.argument<String>("id")!!
          val type = call.argument<Int>("type")!!
          val mediaUri = photoManager.getMediaUri(id, type)
          resultHandler.reply(mediaUri)
        }
      }
      "getPropertiesFromAssetEntity" -> {
        runOnBackground {
          val id = call.argument<String>("id")!!
          val asset = photoManager.getAssetProperties(id)
          val assetResult = if (asset != null) {
            ConvertUtils.convertToAssetResult(asset)
          } else {
            null
          }
          resultHandler.reply(assetResult)
        }
      }
      "fetchPathProperties" -> {
        runOnBackground {
          val id = call.argument<String>("id")!!
          val type = call.argument<Int>("type")!!
          val timestamp = getTimeStamp()
          val option = call.getOption()
          val pathEntity = photoManager.getPathEntity(id, type, timestamp, option)
          if (pathEntity != null) {
            val mapResult = ConvertUtils.convertToGalleryResult(listOf(pathEntity))
            resultHandler.reply(mapResult)
          } else {
            resultHandler.reply(null)
          }
        }
      }
      "getLatLngAndroidQ" -> {
        runOnBackground {
          val id = call.argument<String>("id")!!
          // 读取id
          val location = photoManager.getLocation(id)
          resultHandler.reply(location)
        }
      }
      "notify" -> {
        runOnBackground {
          val notify = call.argument<Boolean>("notify")
          if (notify == true) {
            notifyChannel.startNotify()
          } else {
            notifyChannel.stopNotify()
          }
        }
      }
      "deleteWithIds" -> {
        runOnBackground {
          val ids = call.argument<List<String>>("ids")!!
          val list: List<String> = photoManager.deleteAssetWithIds(ids)
          resultHandler.reply(list)
        }
      }
      "saveImage" -> {
        runOnBackground {
          try {
            val image = call.argument<ByteArray>("image")!!
            val title = call.argument<String>("title") ?: ""
            val desc = call.argument<String>("desc") ?: ""
            val entity = photoManager.saveImage(image, title, desc)
            if (entity == null) {
              resultHandler.reply(null)
              return@runOnBackground
            }
            val map = ConvertUtils.convertToAssetResult(entity)
            resultHandler.reply(map)
          } catch (e: Exception) {
            LogUtils.error("save image error", e)
            resultHandler.reply(null)
          }
        }
      }
      "saveImageWithPath" -> {
        runOnBackground {
          try {
            val imagePath = call.argument<String>("path")!!
            val title = call.argument<String>("title") ?: ""
            val desc = call.argument<String>("desc") ?: ""
            val entity = photoManager.saveImage(imagePath, title, desc)
            if (entity == null) {
              resultHandler.reply(null)
              return@runOnBackground
            }
            val map = ConvertUtils.convertToAssetResult(entity)
            resultHandler.reply(map)
          } catch (e: Exception) {
            LogUtils.error("save image error", e)
            resultHandler.reply(null)
          }
        }
      }
      "saveVideo" -> {
        runOnBackground {
          try {
            val videoPath = call.argument<String>("path")!!
            val title = call.argument<String>("title")!!
            val desc = call.argument<String>("desc") ?: ""
            val entity = photoManager.saveVideo(videoPath, title, desc)
            if (entity == null) {
              resultHandler.reply(null)
              return@runOnBackground
            }
            val map = ConvertUtils.convertToAssetResult(entity)
            resultHandler.reply(map)
          } catch (e: Exception) {
            LogUtils.error("save video error", e)
            resultHandler.reply(null)
          }
        }
      }
      "copyAsset" -> {
        runOnBackground {
          val assetId = call.argument<String>("assetId")!!
          val galleryId = call.argument<String>("galleryId")!!
          photoManager.copyToGallery(assetId, galleryId, resultHandler)
        }
      }
      "moveAssetToPath" -> {
        runOnBackground {
          val assetId = call.argument<String>("assetId")!!
          val albumId = call.argument<String>("albumId")!!
          photoManager.moveToGallery(assetId, albumId, resultHandler)
        }
      }
      "removeNoExistsAssets" -> {
        runOnBackground {
          photoManager.removeAllExistsAssets(resultHandler)
        }
      }
      "getFileSize" -> {
        runOnBackground {
          val assetId = call.argument<String>("id")!!
          photoManager.getFileSize(assetId, resultHandler)
        }
      }
      else -> resultHandler.notImplemented()
    }
  }

  private fun getTimeStamp(): Long {
    return 0
  }

  private fun MethodCall.getString(key: String): String {
    return this.argument<String>(key)!!
  }

  private fun MethodCall.getInt(key: String): Int {
    return this.argument<Int>(key)!!
  }

  private fun MethodCall.getOption(): FilterOption {
    val arguments = argument<Map<*, *>>("option")!!
    return ConvertUtils.convertFilterOptionsFromMap(arguments)
  }
}