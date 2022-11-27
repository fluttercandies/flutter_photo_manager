package com.fluttercandies.photo_manager.permission

import android.Manifest
import android.annotation.TargetApi
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import com.fluttercandies.photo_manager.constant.Methods
import com.fluttercandies.photo_manager.core.utils.RequestTypeUtils
import com.fluttercandies.photo_manager.util.LogUtils
import com.fluttercandies.photo_manager.util.ResultHandler
import io.flutter.plugin.common.MethodCall
import java.lang.IllegalStateException
import java.lang.NullPointerException
import java.util.ArrayList

class PermissionsUtils {
    /** 需要申请权限的Activity */
    private var mActivity: Activity? = null

    /** 是否正在请求权限 */
    var isRequesting = false
        private set

    /**
     * 需要申请的权限的List
     */
    private val needToRequestPermissionsList: MutableList<String> = ArrayList()

    /**
     * 拒绝授权的权限的List
     */
    private val deniedPermissionsList: MutableList<String> = ArrayList()

    /**
     * 允许的权限List
     */
    private val grantedPermissionsList: MutableList<String> = ArrayList()

    /**
     * 某次进行权限申请的requestCode
     */
    private var requestCode = 0

    /**
     * 授权监听回调
     */
    var permissionsListener: PermissionsListener? = null

    /**
     * 设置是哪一个Activity进行权限操作
     *
     * @param activity 哪一个Activity进行权限操作
     * @return 返回 [PermissionsUtils] 自身，进行链式调用
     */
    fun withActivity(activity: Activity?): PermissionsUtils {
        mActivity = activity
        return this
    }

    /**
     * 进行权限申请，不带拒绝弹框提示
     *
     * @param requestCode 指定该次申请的requestCode
     * @param permissions 要申请的权限数组
     * @return 返回 [PermissionsUtils] 自身，进行链式调用
     */
    fun getPermissions(requestCode: Int, permissions: List<String>): PermissionsUtils {
        return getPermissionsWithTips(requestCode, *permissions.toTypedArray())
    }

    /**
     * 进行权限申请，带拒绝弹框提示
     *
     * @param requestCode 指定该次申请的requestCode
     * @param permissions 要申请的权限数组
     * @return 返回 [PermissionsUtils] 自身，进行链式调用
     */
    @TargetApi(23)
    private fun getPermissionsWithTips(
        requestCode: Int,
        vararg permissions: String
    ): PermissionsUtils {
        if (mActivity == null) {
            throw NullPointerException("Activity for the permission request is not exist.")
        }
        check(!isRequesting) { "Another permission request is ongoing." }
        isRequesting = true
        this.requestCode = requestCode
        if (!checkPermissions(*permissions)) {
            // 通过上面的 checkPermissions，可以知道能得到进入到这里面的都是 6.0 的机子
            ActivityCompat.requestPermissions(
                mActivity!!,
                needToRequestPermissionsList.toTypedArray(),
                requestCode
            )
            for (i in needToRequestPermissionsList.indices) {
                LogUtils.info("Permissions: " + needToRequestPermissionsList[i])
            }
        } else if (permissionsListener != null) {
            isRequesting = false
            permissionsListener!!.onGranted()
        }
        return this
    }

    /**
     * 检查所需权限是否已获取
     *
     * @param permissions 所需权限数组
     * @return 是否全部已获取
     */
    private fun checkPermissions(vararg permissions: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            resetStatus()
            for (p in permissions) {
                if (mActivity!!.checkSelfPermission(p) == PackageManager.PERMISSION_DENIED) {
                    // Add the denied permission to the pending list.
                    needToRequestPermissionsList.add(p)
                }
            }
            return needToRequestPermissionsList.isEmpty()
        }
        return true
    }

    /**
     * 处理申请权限返回
     * 由于某些rom对权限进行了处理，第一次选择了拒绝，则不会出现第二次询问（或者没有不再询问），故拒绝就回调onDenied
     *
     * @param requestCode  对应申请权限时的code
     * @param permissions  申请的权限数组
     * @param grantResults 是否申请到权限数组
     * @return 返回 [PermissionsUtils] 自身，进行链式调用
     */
    fun dealResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ): PermissionsUtils {
        if (requestCode == this.requestCode) {
            for (i in permissions.indices) {
                LogUtils.info("Returned permissions: " + permissions[i])
                if (grantResults[i] == PackageManager.PERMISSION_DENIED) {
                    deniedPermissionsList.add(permissions[i])
                } else if (grantResults[i] == PackageManager.PERMISSION_GRANTED) {
                    grantedPermissionsList.add(permissions[i])
                }
            }
            if (deniedPermissionsList.isNotEmpty()) {
                // 回调用户拒绝监听
                permissionsListener!!.onDenied(deniedPermissionsList, grantedPermissionsList)
            } else {
                // 回调用户同意监听
                permissionsListener!!.onGranted()
            }
        }
        isRequesting = false
        return this
    }

    /**
     * 恢复状态
     */
    private fun resetStatus() {
        if (deniedPermissionsList.isNotEmpty()) deniedPermissionsList.clear()
        if (needToRequestPermissionsList.isNotEmpty()) needToRequestPermissionsList.clear()
    }

    /**
     * 跳转到应用的设置界面
     *
     * @param context 上下文
     */
    fun getAppDetailSettingIntent(context: Context?) {
        val localIntent = Intent()
        localIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        localIntent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
        localIntent.addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
        localIntent.addCategory(Intent.CATEGORY_DEFAULT)
        localIntent.action = "android.settings.APPLICATION_DETAILS_SETTINGS"
        localIntent.data = Uri.fromParts("package", context!!.packageName, null)
        context.startActivity(localIntent)
    }

    fun needWriteExternalStorage(call: MethodCall): Boolean {
        return when (call.method) {
            Methods.saveImage,
            Methods.saveImageWithPath,
            Methods.saveVideo,
            Methods.copyAsset,
            Methods.moveAssetToPath,
            Methods.deleteWithIds,
            Methods.removeNoExistsAssets -> true

            else -> false
        }
    }

    fun needAccessLocation(call: MethodCall): Boolean {
        return when (call.method) {
            Methods.copyAsset,
            Methods.getLatLng,
            Methods.getOriginBytes -> true

            Methods.getFullFile -> call.argument<Boolean>("isOrigin")!! && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
            else -> false
        }
    }

    @RequiresApi(33)
    fun addManifestWithPermission33(
        context: Context,
        permissions: ArrayList<String>,
        call: MethodCall,
        resultHandler: ResultHandler
    ) {
        val method = call.method
        if (method == Methods.requestPermissionExtend) {
            // Check all permissions listed in the manifest, regardless the request type.
            if (havePermissionInManifest(context, Manifest.permission.READ_MEDIA_IMAGES)) {
                permissions.add(Manifest.permission.READ_MEDIA_IMAGES)
            }
            if (havePermissionInManifest(context, Manifest.permission.READ_MEDIA_VIDEO)) {
                permissions.add(Manifest.permission.READ_MEDIA_VIDEO)
            }
            if (havePermissionInManifest(context, Manifest.permission.READ_MEDIA_AUDIO)) {
                permissions.add(Manifest.permission.READ_MEDIA_AUDIO)
            }
            return
        } else if (!Methods.android13PermissionMethods.contains(method)) {
            return
        }

        val type = call.argument<Int>("type")
        if (type == null) {
            resultHandler.replyError("The $method must pass the 'type' params")
            return
        }
        val haveImage = RequestTypeUtils.containsImage(type)
        val haveVideo = RequestTypeUtils.containsVideo(type)
        val haveAudio = RequestTypeUtils.containsAudio(type)

        fun checkAndAddPermission(requestHavePermission: Boolean, tag: String, manifestPermission: String) {
            if (!requestHavePermission) {
                return
            }

            if (!havePermissionInManifest(context, manifestPermission)) {
                throw IllegalStateException("Request $tag must have $manifestPermission in manifest.")
            }
            permissions.add(manifestPermission)
        }

        try {
            checkAndAddPermission(haveImage, "image", Manifest.permission.READ_MEDIA_IMAGES)
            checkAndAddPermission(haveVideo, "video", Manifest.permission.READ_MEDIA_VIDEO)
            checkAndAddPermission(haveAudio, "audio", Manifest.permission.READ_MEDIA_AUDIO)
        } catch (e: IllegalStateException) {
            resultHandler.replyError("Permissions check error", e.message, e)
        }

    }

    fun havePermissionInManifest(context: Context, permission: String): Boolean {
        val applicationInfo = context.applicationInfo
        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.packageManager.getPackageInfo(
                applicationInfo.packageName,
                PackageManager.PackageInfoFlags.of(PackageManager.GET_PERMISSIONS.toLong())
            )
        } else {
            @Suppress("DEPRECATION")
            context.packageManager.getPackageInfo(
                applicationInfo.packageName,
                PackageManager.GET_PERMISSIONS
            )
        }
        return packageInfo.requestedPermissions.contains(permission)
    }
}
