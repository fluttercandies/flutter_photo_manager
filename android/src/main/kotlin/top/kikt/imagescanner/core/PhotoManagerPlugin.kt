package top.kikt.imagescanner.core

import android.Manifest
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
            "getAssetWithGalleryId" -> {
                runOnBackground {
                    val id = call.argument<String>("id") as String
                    val page = call.argument<Int>("page") as Int
                    val pageCount = call.argument<Int>("pageCount") as Int
                    val type = call.argument<Int>("type") as Int
                    val list = photoManager.getAssetList(id, page, pageCount, type)
                    resultHandler.reply(ConvertUtils.convertToAssetResult(list))
                }
                true
            }
            "getThumb" -> {
                val id = call.argument<String>("id") as String
                val width = call.argument<Int>("width") as Int
                val height = call.argument<Int>("height") as Int
                photoManager.getThumb(id, width, height, resultHandler)
                true
            }
            "getOrigin" -> {
                runOnBackground {
                    val id = call.argument<String>("id") as String
                    photoManager.getOriginBytes(id, resultHandler)
                }
                true
            }
            "releaseMemCache" -> {
                photoManager.clearCache()
                true
            }
            "log" -> {
                LogUtils.isLog = call.arguments()
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
                            runOnBackground {
                                val type = call.argument<Int>("type") as Int
                                val list = photoManager.getGalleryList(type)
                                resultHandler.reply(ConvertUtils.convertToGalleryResult(list))
                            }
                        }
                        else -> resultHandler.notImplemented()
                    }
                }
            }
        }.getPermissions(registrar.activity(), 3001, Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE)

    }
}