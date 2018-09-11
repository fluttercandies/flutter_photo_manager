package top.kikt.imagescanner

import android.Manifest
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

    override fun onMethodCall(call: MethodCall, result: Result): Unit {
        val permissionsUtils = PermissionsUtils()
        registrar.addRequestPermissionsResultListener { i, strings, ints ->
            permissionsUtils.dealResult(i, strings, ints)
            true
        }
        permissionsUtils.apply {
            withActivity(registrar.activity())
            permissionsListener = object : PermissionsListener {
                override fun onDenied(deniedPermissions: Array<out String>?) {
                    result.error("失败", "权限被拒绝", "")
                }

                override fun onGranted() {
                    when {
                        call.method == "getGalleryIdList" -> scanner.scanAndGetImageIdList(result)
                        call.method == "getGalleryNameList" -> scanner.getPathListWithPathIds(call, result)
                        call.method == "getImageListWithPathId" -> scanner.getImageListWithPathId(call, result)
                        call.method == "getImageThumbListWithPathId" -> scanner.getImageThumbListWithPathId(call, result)
                        call.method == "getThumbPath" -> scanner.getImageThumb(call, result)
                        else -> result.notImplemented()
                    }
                }
            }
        }.getPermissions(registrar.activity(), 3001, Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE)
    }

}

data class Img(val path: String, val imgId: String, val dir: String, val dirId: String, val title: String, var thumb: String?)