package com.fluttercandies.photo_manager.core

import android.app.Activity
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.bumptech.glide.Glide
import com.fluttercandies.photo_manager.constant.Methods
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.entity.PermissionResult
import com.fluttercandies.photo_manager.core.entity.ThumbLoadOption
import com.fluttercandies.photo_manager.core.entity.filter.FilterOption
import com.fluttercandies.photo_manager.core.utils.ConvertUtils
import com.fluttercandies.photo_manager.permission.PermissionsListener
import com.fluttercandies.photo_manager.permission.PermissionsUtils
import com.fluttercandies.photo_manager.util.LogUtils
import com.fluttercandies.photo_manager.util.ResultHandler
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit

class PhotoManagerPlugin(
    private val applicationContext: Context,
    messenger: BinaryMessenger,
    private var activity: Activity?,
    private val permissionsUtils: PermissionsUtils
) : MethodChannel.MethodCallHandler {
    companion object {
        private const val POOL_SIZE = 8
        private val threadPool: ThreadPoolExecutor = ThreadPoolExecutor(
            POOL_SIZE,
            Int.MAX_VALUE,
            1,
            TimeUnit.MINUTES,
            LinkedBlockingQueue()
        )

        fun runOnBackground(runnable: () -> Unit) {
            threadPool.execute(runnable)
        }
    }

    init {
        permissionsUtils.permissionsListener = object : PermissionsListener {
            override fun onGranted(needPermissions: MutableList<String>) {}
            override fun onDenied(
                deniedPermissions: MutableList<String>,
                grantedPermissions: MutableList<String>,
                needPermissions: MutableList<String>,
            ) {
            }
        }
    }

    val deleteManager = PhotoManagerDeleteManager(applicationContext, activity)

    fun bindActivity(activity: Activity?) {
        this.activity = activity
        permissionsUtils.withActivity(activity)
        deleteManager.bindActivity(activity)
    }

    private val notifyChannel = PhotoManagerNotifyChannel(
        applicationContext,
        messenger,
        Handler(Looper.getMainLooper())
    )

    private val photoManager = PhotoManager(applicationContext)

    private var ignorePermissionCheck = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val resultHandler = ResultHandler(result, call)
        val method = call.method

        if (Methods.isNotNeedPermissionMethod(method)) {
            // The method does not need permission.
            // Usually, these methods are used to config the plugin or get some info.
            handleNotNeedPermissionMethod(resultHandler)
            return
        }


        if (Methods.isPermissionMethod(method)) {
            // The method is used to request permission.
            handlePermissionMethod(resultHandler)
            return
        }

        if (ignorePermissionCheck) {
            handleOtherMethods(resultHandler)
            return
        }

        handleOtherMethods(resultHandler)

//        permissionsUtils.withActivity(activity)
//            .handlePermission(resultHandler, this::onHandlePermissionResult)

//        if (permissionsUtils.isRequesting) {
//            resultHandler.replyError(
//                "PERMISSION_REQUESTING",
//                "Another permission request is still ongoing. Please request after the existing one is done.",
//                null
//            )
//            return
//        }
//
//        val needWritePermission =
//            permissionsUtils.needWriteExternalStorage(call)
//                    && Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q
//                    && permissionsUtils.havePermissionInManifest(
//                applicationContext,
//                Manifest.permission.WRITE_EXTERNAL_STORAGE
//            )
//        val needReadPermission =
//            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU
//                    && permissionsUtils.havePermissionInManifest(
//                applicationContext,
//                Manifest.permission.READ_EXTERNAL_STORAGE
//            )
//        val needLocationPermission =
//            permissionsUtils.needAccessLocation(call)
//                    && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
//                    && permissionsUtils.havePermissionInManifest(
//                applicationContext,
//                Manifest.permission.ACCESS_MEDIA_LOCATION
//            )
//        val permissions = arrayListOf<String>()
//        if (needReadPermission) {
//            permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
//        }
//        if (needWritePermission) {
//            permissions.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
//        }
//        if (needLocationPermission) {
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
//                permissions.add(Manifest.permission.ACCESS_MEDIA_LOCATION)
//            }
//        }
//
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
//            permissionsUtils.addManifestWithPermission33(
//                applicationContext,
//                permissions,
//                call,
//                resultHandler
//            )
//            if (resultHandler.isReplied()) {
//                return
//            }
//        }
//
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
//            if (Methods.presentLimited == call.method) {
//                val havePermissionInManifest = permissionsUtils.havePermissionInManifest(
//                    applicationContext,
//                    Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED
//                )
//                if (!havePermissionInManifest) {
//                    resultHandler.replyError("The ${Methods.presentLimited} must have READ_MEDIA_VISUAL_USER_SELECTED in manifest.")
//                    return
//                }
//            }
//
//            permissionsUtils.addManifestWithPermission34(
//                applicationContext,
//                permissions,
//                call,
//                resultHandler
//            )
//        } else {
//            if (Methods.presentLimited == call.method) {
//                resultHandler.replyError("The ${Methods.presentLimited} must use Android 14(API 34) or higher.")
//                return
//            }
//        }
//
//        val utils = permissionsUtils.apply {
//            withActivity(activity)
//            permissionsListener = object : PermissionsListener {
//                override fun onGranted() {
//                    LogUtils.info("onGranted call.method = ${call.method}")
//                    onHandlePermissionResult(call, resultHandler, needLocationPermission)
//                }
//
//                override fun onDenied(
//                    deniedPermissions: MutableList<String>,
//                    grantedPermissions: MutableList<String>
//                ) {
//                    LogUtils.info("onDenied call.method = ${call.method}")
//                    if (call.method == Methods.requestPermissionExtend) {
//                        resultHandler.reply(PermissionResult.Denied.value)
//                        return
//                    }
//                    if (grantedPermissions.containsAll(permissions)) {
//                        LogUtils.info("onGranted call.method = ${call.method}")
//                        onHandlePermissionResult(call, resultHandler, needLocationPermission)
//                    } else {
//                        replyPermissionError(resultHandler)
//                    }
//                }
//            }
//        }
//
//        utils.getPermissions(3001, permissions)
    }

    private fun handlePermissionMethod(resultHandler: ResultHandler) {
        val call = resultHandler.call
        when (call.method) {
            Methods.requestPermissionExtend -> {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                    resultHandler.reply(PermissionResult.Authorized.value)
                    return
                }

                val androidPermission = call.argument<Map<*, *>>("androidPermission")!!
                val requestType = androidPermission["type"] as Int
                val mediaLocation = androidPermission["mediaLocation"] as Boolean

                permissionsUtils.withActivity(activity)
                    .setListener(object : PermissionsListener {
                        override fun onGranted(needPermissions: MutableList<String>) {
                            resultHandler.reply(
                                permissionsUtils.getAuthValue(requestType, mediaLocation).value
                            )
                        }

                        override fun onDenied(
                            deniedPermissions: MutableList<String>,
                            grantedPermissions: MutableList<String>,
                            needPermissions: MutableList<String>
                        ) {
                            val authResult =
                                permissionsUtils.getAuthValue(requestType, mediaLocation)
                            resultHandler.reply(authResult.value)
//                            resultHandler.reply()
//                            if (grantedPermissions.containsAll(needPermissions)) {
//                                resultHandler.reply(authResult.value)
//                            } else {
//                                resultHandler.reply(PermissionResult.Denied.value)
//                            }
                        }
                    })
                    .requestPermission(
                        applicationContext,
                        requestType,
                        mediaLocation,
                    )
            }

            Methods.presentLimited -> {
                val type = call.argument<Int>("type")!!
                permissionsUtils.presentLimited(type, resultHandler)
            }
        }

    }

    private fun handleOtherMethods(resultHandler: ResultHandler) {
        runOnBackground {
            try {
                val needLocationPermission =
                    permissionsUtils.haveLocationPermission(applicationContext)
                handleMethodResult(resultHandler, needLocationPermission)
            } catch (e: Exception) {
                val call = resultHandler.call
                val method = call.method
                val params = call.arguments
                resultHandler.replyError(
                    "The $method method has an error: ${e.message}",
                    e.stackTraceToString(),
                    params
                )
            }
        }
    }

    private fun handleNotNeedPermissionMethod(resultHandler: ResultHandler) {
        val call = resultHandler.call
        when (call.method) {
            Methods.log -> {
                LogUtils.isLog = call.arguments() ?: false
                resultHandler.reply(1)
            }

            Methods.openSetting -> {
                permissionsUtils.getAppDetailSettingIntent(activity)
                resultHandler.reply(1)
            }

            Methods.forceOldAPI -> {
                photoManager.useOldApi = true
                resultHandler.reply(1)
            }

            Methods.systemVersion -> {
                resultHandler.reply(Build.VERSION.SDK_INT.toString())
            }

            Methods.clearFileCache -> {
                Glide.get(applicationContext).clearMemory()
                runOnBackground {
                    photoManager.clearFileCache()
                    resultHandler.reply(1)
                }
            }

            Methods.releaseMemoryCache -> {
                // The plugin will not hold instances cache on Android.
                resultHandler.reply(1)
            }

            Methods.ignorePermissionCheck -> {
                val ignore = call.argument<Boolean>("ignore")!!
                ignorePermissionCheck = ignore
                resultHandler.reply(ignore)
            }

            Methods.getPermissionState -> {
                val androidPermission = call.argument<Map<*, *>>("androidPermission")!!
                val requestType = androidPermission["type"] as Int
                val mediaLocation = androidPermission["mediaLocation"] as Boolean
                permissionsUtils.getAuthValue(requestType, mediaLocation).let {
                    resultHandler.reply(it.value)
                }
            }
        }
    }

    private fun replyPermissionError(resultHandler: ResultHandler) {
        resultHandler.replyError(
            "Request for permission failed.",
            "User denied permission.",
            null
        )
    }

    private fun handleMethodResult(
        resultHandler: ResultHandler,
        needLocationPermission: Boolean
    ) {
        val call = resultHandler.call
        when (call.method) {
            Methods.getAssetPathList -> {
                val type = call.argument<Int>("type")!!
                val hasAll = call.argument<Boolean>("hasAll")!!
                val option = call.getOption()
                val onlyAll = call.argument<Boolean>("onlyAll")!!

                val list = photoManager.getAssetPathList(type, hasAll, onlyAll, option)
                resultHandler.reply(ConvertUtils.convertPaths(list))
            }

            Methods.getAssetListPaged -> {
                val galleryId = call.argument<String>("id")!!
                val type = call.argument<Int>("type")!!
                val page = call.argument<Int>("page")!!
                val size = call.argument<Int>("size")!!
                val option = call.getOption()
                val list =
                    photoManager.getAssetListPaged(galleryId, type, page, size, option)
                resultHandler.reply(ConvertUtils.convertAssets(list))
            }

            Methods.getAssetCountFromPath -> {
                val galleryId = call.getString("id")
                val type = call.getInt("type")
                val option = call.getOption()

                photoManager.getAssetCount(resultHandler, option, type, galleryId)
            }

            Methods.getAssetListRange -> {
                val galleryId = call.getString("id")
                val type = call.getInt("type")
                val start = call.getInt("start")
                val end = call.getInt("end")
                val option = call.getOption()
                val list: List<AssetEntity> =
                    photoManager.getAssetListRange(galleryId, type, start, end, option)
                resultHandler.reply(ConvertUtils.convertAssets(list))
            }

            Methods.getThumbnail -> {
                val id = call.argument<String>("id")!!
                val optionMap = call.argument<Map<*, *>>("option")!!
                val option = ThumbLoadOption.fromMap(optionMap)
                photoManager.getThumb(id, option, resultHandler)
            }

            Methods.requestCacheAssetsThumbnail -> {
                val ids = call.argument<List<String>>("ids")!!
                val optionMap = call.argument<Map<*, *>>("option")!!
                val option = ThumbLoadOption.fromMap(optionMap)
                photoManager.requestCache(ids, option, resultHandler)
            }

            Methods.cancelCacheRequests -> {
                photoManager.cancelCacheRequests()
                resultHandler.reply(null)
            }

            Methods.assetExists -> {
                val id = call.argument<String>("id")!!
                photoManager.assetExists(id, resultHandler)
            }

            Methods.getFullFile -> {
                val id = call.argument<String>("id")!!
                val isOrigin =
                    if (!needLocationPermission) false else call.argument<Boolean>("isOrigin")!!
                photoManager.getFile(id, isOrigin, resultHandler)
            }

            Methods.getOriginBytes -> {
                val id = call.argument<String>("id")!!
                photoManager.getOriginBytes(id, resultHandler, needLocationPermission)
            }

            Methods.getMediaUrl -> {
                val id = call.argument<String>("id")!!
                val type = call.argument<Int>("type")!!
                val mediaUri = photoManager.getMediaUri(id.toLong(), type)
                resultHandler.reply(mediaUri)
            }

            Methods.fetchEntityProperties -> {
                val id = call.argument<String>("id")!!
                val asset = photoManager.fetchEntityProperties(id)
                val assetResult = if (asset != null) {
                    ConvertUtils.convertAsset(asset)
                } else {
                    null
                }
                resultHandler.reply(assetResult)
            }

            Methods.fetchPathProperties -> {
                val id = call.argument<String>("id")!!
                val type = call.argument<Int>("type")!!
                val option = call.getOption()
                val pathEntity = photoManager.fetchPathProperties(id, type, option)
                if (pathEntity != null) {
                    val mapResult = ConvertUtils.convertPaths(listOf(pathEntity))
                    resultHandler.reply(mapResult)
                } else {
                    resultHandler.reply(null)
                }
            }

            Methods.getLatLng -> {
                val id = call.argument<String>("id")!!
                // 读取id
                val location = photoManager.getLocation(id)
                resultHandler.reply(location)
            }

            Methods.notify -> {
                val notify = call.argument<Boolean>("notify")
                if (notify == true) {
                    notifyChannel.startNotify()
                } else {
                    notifyChannel.stopNotify()
                }
                resultHandler.reply(null)
            }

            Methods.saveImage -> {
                try {
                    val bytes = call.argument<ByteArray>("image")!!
                    val filename = call.argument<String>("filename") ?: ""
                    val title = call.argument<String>("title") ?: ""
                    val desc = call.argument<String>("desc") ?: ""
                    val relativePath = call.argument<String>("relativePath") ?: ""
                    val orientation = call.argument<Int?>("orientation")
                    val entity = photoManager.saveImage(
                        bytes,
                        filename,
                        title,
                        desc,
                        relativePath,
                        orientation,
                    )
                    val map = ConvertUtils.convertAsset(entity)
                    resultHandler.reply(map)
                } catch (e: Exception) {
                    LogUtils.error("save image error", e)
                    resultHandler.replyError(call.method, message = null, obj = e)
                }
            }

            Methods.saveImageWithPath -> {
                try {
                    val filePath = call.argument<String>("path")!!
                    val title = call.argument<String>("title") ?: ""
                    val desc = call.argument<String>("desc") ?: ""
                    val relativePath = call.argument<String>("relativePath") ?: ""
                    val orientation = call.argument<Int?>("orientation")
                    val entity = photoManager.saveImage(
                        filePath,
                        title,
                        desc,
                        relativePath,
                        orientation,
                    )
                    val map = ConvertUtils.convertAsset(entity)
                    resultHandler.reply(map)
                } catch (e: Exception) {
                    LogUtils.error("save image error", e)
                    resultHandler.replyError(call.method, message = null, obj = e)
                }
            }

            Methods.saveVideo -> {
                try {
                    val filePath = call.argument<String>("path")!!
                    val title = call.argument<String>("title")!!
                    val desc = call.argument<String>("desc") ?: ""
                    val relativePath = call.argument<String>("relativePath") ?: ""
                    val orientation = call.argument<Int?>("orientation")
                    val entity = photoManager.saveVideo(
                        filePath,
                        title,
                        desc,
                        relativePath,
                        orientation,
                    )
                    val map = ConvertUtils.convertAsset(entity)
                    resultHandler.reply(map)
                } catch (e: Exception) {
                    LogUtils.error("save video error", e)
                    resultHandler.replyError(call.method, message = null, obj = e)
                }
            }

            Methods.copyAsset -> {
                val assetId = call.argument<String>("assetId")!!
                val galleryId = call.argument<String>("galleryId")!!
                photoManager.copyToGallery(assetId, galleryId, resultHandler)
            }

            Methods.moveAssetToPath -> {
                val assetId = call.argument<String>("assetId")!!
                val albumId = call.argument<String>("albumId")!!
                photoManager.moveToGallery(assetId, albumId, resultHandler)
            }

            Methods.deleteWithIds -> {
                try {
                    val ids = call.argument<List<String>>("ids")!!
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val uris = ids.map { photoManager.getUri(it) }.toList()
                        deleteManager.deleteInApi30(uris, resultHandler)
                    } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
                        val idUriMap = HashMap<String, Uri?>()
                        for (id in ids) {
                            val uri = photoManager.getUri(id)
                            idUriMap[id] = uri
                        }
                        deleteManager.deleteJustInApi29(idUriMap, resultHandler)
                    } else {
                        deleteManager.deleteInApi28(ids)
                        resultHandler.reply(ids)
                    }
                } catch (e: Exception) {
                    LogUtils.error("deleteWithIds failed", e)
                    resultHandler.replyError("deleteWithIds failed")
                }
            }

            Methods.moveToTrash -> {
                try {
                    val ids = call.argument<List<String>>("ids")!!
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val uris = ids.map { photoManager.getUri(it) }.toList()
                        deleteManager.moveToTrashInApi30(uris, resultHandler)
                    } else {
                        LogUtils.error("The API 29 or lower have not the IS_TRASHED row in MediaStore.")
                        resultHandler.replyError(
                            "The api not support 29 or lower.",
                            "",
                            UnsupportedOperationException("The api cannot be used in 29 or lower.")
                        )
                    }
                } catch (e: Exception) {
                    LogUtils.error("deleteWithIds failed", e)
                    resultHandler.replyError("deleteWithIds failed")
                }
            }

            Methods.removeNoExistsAssets -> {
                photoManager.removeAllExistsAssets(resultHandler)
            }

            Methods.getColumnNames -> {
                photoManager.getColumnNames(resultHandler)
            }

            Methods.getAssetCount -> {
                val option = call.getOption()
                val type = call.getInt("type")
                photoManager.getAssetCount(resultHandler, option, type)
            }

            Methods.getAssetsByRange -> {
                val option = call.getOption()
                val start = call.getInt("start")
                val end = call.getInt("end")
                val type = call.getInt("type")
                photoManager.getAssetsByRange(resultHandler, option, start, end, type)
            }

            else -> resultHandler.notImplemented()
        }
    }

    private fun MethodCall.getString(key: String): String {
        return this.argument<String>(key)!!
    }

    private fun MethodCall.getInt(key: String): Int {
        return this.argument<Int>(key)!!
    }

    private fun MethodCall.getOption(): FilterOption {
        val arguments = argument<Map<*, *>>("option")!!
        return ConvertUtils.convertToFilterOptions(arguments)
    }
}
