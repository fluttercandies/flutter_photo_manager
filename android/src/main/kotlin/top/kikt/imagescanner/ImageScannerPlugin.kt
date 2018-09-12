package top.kikt.imagescanner

import android.Manifest
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar


class ImageScannerPlugin(val registrar: Registrar) : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {
            val channel = MethodChannel(registrar.messenger(), "image_scanner")
            channel.setMethodCallHandler(ImageScannerPlugin(registrar))
        }
    }

    val scanner = ImageScanner(registrar)
    private val permissionsUtils = PermissionsUtils()

    init {
        registrar.addRequestPermissionsResultListener { i, strings, ints ->
            permissionsUtils.dealResult(i, strings, ints)
            true
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result): Unit {
        if (call.method == "openSetting") {
            result.success("")
            permissionsUtils.getAppDetailSettingIntent(registrar.activity())
            return
        }

        val handleResult = when {
            call.method == "getGalleryNameList" -> {
                scanner.getPathListWithPathIds(call, result)
                true
            }
            call.method == "getImageListWithPathId" -> {
                scanner.getImageListWithPathId(call, result)
                true
            }
            call.method == "getImageThumbListWithPathId" -> {
                scanner.getImageThumbListWithPathId(call, result)
                true
            }
            call.method == "getThumbPath" -> {
                scanner.getImageThumb(call, result)
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
                    Log.i("permission", "onDenied")
                    if (call.method == "requestPermission") {
                        result.success(0)
                    } else {
                        result.error("失败", "权限被拒绝", "")
                    }
                }

                override fun onGranted() {
                    Log.i("permission", "onGranted")
                    when {
                        call.method == "requestPermission" -> result.success(1)
                        call.method == "getGalleryIdList" -> scanner.scanAndGetImageIdList(result)
                    }
                }
            }
        }.getPermissions(registrar.activity(), 3001, Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE)


    }

}

data class Img(val path: String, val imgId: String, val dir: String, val dirId: String, val title: String, var thumb: String?)