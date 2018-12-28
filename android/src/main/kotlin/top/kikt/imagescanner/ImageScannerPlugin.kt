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
            false
        }
        permissionsUtils.permissionsListener = object : PermissionsListener {
            override fun onDenied(deniedPermissions: Array<out String>?) {
            }

            override fun onGranted() {
            }
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
            call.method == "getAllImageList" -> {
                scanner.getAllImageList(call, result)
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
            call.method == "getThumbBytesWithId" -> {
                scanner.getImageThumbData(call, result)
                true
            }
            call.method == "createThumbWithPathId" -> {
                scanner.createThumbWithPathId(call, result)
                true
            }
            call.method == "createThumbWithPathIdAndIndex" -> {
                scanner.createThumbWithPathIdAndIndex(call, result)
                true
            }
            call.method == "getAssetTypeWithIds" -> {
                scanner.getAssetTypeWithIds(call, result)
                true
            }
            call.method == "getDurationWithId" -> {
                scanner.getAssetDurationWithId(call, result)
                true
            }
            else -> false
        }

        if (handleResult) {
            return
        }


        var r: Result? = result

        permissionsUtils.apply {
            withActivity(registrar.activity())
            permissionsListener = object : PermissionsListener {
                override fun onDenied(deniedPermissions: Array<out String>?) {
                    Log.i("permission", "onDenied call.method = ${call.method}")
                    val localResult = r
                    r = null
                    if (call.method == "requestPermission") {
                        localResult?.success(0)
                    } else {
                        localResult?.error("失败", "权限被拒绝", "")
                    }
                }

                override fun onGranted() {
                    Log.i("permission", "onGranted call.method = ${call.method}")
                    val localResult = r
                    r = null
                    when {
                        call.method == "requestPermission" -> localResult?.success(1)
                        call.method == "getGalleryIdList" -> scanner.scanAndGetImageIdList(localResult)
                    }
                }
            }
        }.getPermissions(registrar.activity(), 3001, Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE)


    }

}

data class Img(val path: String, val imgId: String, val dir: String, val dirId: String, val title: String, var thumb: String?, val type: AssetType, val timeStamp: Long, val duration: Long?)

enum class AssetType {
    Other,
    Image,
    Video,
}