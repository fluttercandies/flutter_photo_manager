package top.kikt.imagescanner.core

import android.Manifest
import android.os.Build
import android.os.Handler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import top.kikt.imagescanner.core.utils.ConvertUtils
import top.kikt.imagescanner.old.ResultHandler
import top.kikt.imagescanner.old.permission.PermissionsListener
import top.kikt.imagescanner.old.permission.PermissionsUtils
import top.kikt.imagescanner.util.LogUtils
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit

/// create 2019-09-05 by cai


class PhotoManagerPlugin(private val registrar: PluginRegistry.Registrar) : MethodChannel.MethodCallHandler {

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
    }

    private val permissionsUtils = PermissionsUtils()
    private val notifyChannel = PhotoManagerNotifyChannel(registrar, Handler())

    init {
        registrar.addRequestPermissionsResultListener { i, strings, ints ->
            permissionsUtils.dealResult(i, strings, ints)
            false
        }
        permissionsUtils.permissionsListener = object : PermissionsListener {
            override fun onDenied(deniedPermissions: Array<out String>?) {
            }

            override fun onGranted() {
            }
        }
    }

    private val photoManager = PhotoManager(registrar.context().applicationContext)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val resultHandler = ResultHandler(result)

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
                permissionsUtils.getAppDetailSettingIntent(registrar.activity())
                true
            }
            "androidQExperimental" -> {
                val open = call.argument<Boolean>("open")!!
                photoManager.androidQExperimental = open
                resultHandler.reply(1)
                true
            }
            "forceOldApi" -> {
                photoManager.useOldApi = true
                resultHandler.reply(1)
                true
            }

            else -> false
        }

        if (handleResult) {
            return
        }

        permissionsUtils.apply {
            withActivity(registrar.activity())
            permissionsListener = object : PermissionsListener {
                override fun onDenied(deniedPermissions: Array<out String>?) {
                    LogUtils.info("onDenied call.method = ${call.method}")
                    if (call.method == "requestPermission") {
                        resultHandler.reply(0)
                    } else {
                        resultHandler.replyError("失败", "权限被拒绝", "")
                    }
                }

                override fun onGranted() {
                    LogUtils.info("onGranted call.method = ${call.method}")
                    when (call.method) {
                        "requestPermission" -> resultHandler.reply(1)
                        "getGalleryList" -> {
                            if (Build.VERSION.SDK_INT >= 29) {
                                photoManager.androidQExperimental = true
                                notifyChannel.setAndroidQExperimental(true)
                            }
                            runOnBackground {
                                val type = call.argument<Int>("type")!!
                                val timeStamp = call.getTimeStamp()
                                val hasAll = call.argument<Boolean>("hasAll")!!
                                val list = photoManager.getGalleryList(type, timeStamp, hasAll)
                                resultHandler.reply(ConvertUtils.convertToGalleryResult(list))
                            }
                        }
                        "getAssetWithGalleryId" -> {
                            runOnBackground {
                                val id = call.argument<String>("id") as String
                                val page = call.argument<Int>("page") as Int
                                val pageCount = call.argument<Int>("pageCount") as Int
                                val type = call.argument<Int>("type") as Int
                                val timeStamp = call.getTimeStamp()

                                val list = photoManager.getAssetList(id, page, pageCount, type, timeStamp)
                                resultHandler.reply(ConvertUtils.convertToAssetResult(list))
                            }
                        }
                        "getThumb" -> {
                            val id = call.argument<String>("id") as String
                            val width = call.argument<Int>("width") as Int
                            val height = call.argument<Int>("height") as Int
                            photoManager.getThumb(id, width, height, resultHandler)
                        }
                        "getOrigin" -> {
                            runOnBackground {
                                val id = call.argument<String>("id") as String
                                photoManager.getOriginBytes(id, resultHandler)
                            }
                        }
                        "getFullFile" -> {
                            runOnBackground {
                                val id = call.argument<String>("id")!!
                                val isOrigin = call.argument<Boolean>("isOrigin")!!
                                photoManager.getFile(id, resultHandler)
                            }
                        }
                        "fetchPathProperties" -> {
                            runOnBackground {
                                val id = call.argument<String>("id")!!
                                val type = call.argument<Int>("type")!!
                                val timestamp = call.getTimeStamp()
                                val pathEntity = photoManager.getPathEntity(id, type, timestamp)
                                if (pathEntity != null) {
                                    val mapResult = ConvertUtils.convertToGalleryResult(listOf(pathEntity))
                                    resultHandler.reply(mapResult)
                                } else {
                                    resultHandler.reply(null)
                                }
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
                        else -> resultHandler.notImplemented()
                    }
                }
            }
        }.getPermissions(registrar.activity(), 3001, Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE)

    }

    fun MethodCall.getTimeStamp(): Long {
        return this.argument<Long>("timestamp")!!
    }
}