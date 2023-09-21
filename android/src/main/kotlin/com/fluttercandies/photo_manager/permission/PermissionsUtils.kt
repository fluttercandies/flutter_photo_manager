package com.fluttercandies.photo_manager.permission

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.PermissionChecker
import androidx.core.content.PermissionChecker.PERMISSION_GRANTED
import com.fluttercandies.photo_manager.core.entity.PermissionResult
import com.fluttercandies.photo_manager.util.LogUtils
import com.fluttercandies.photo_manager.util.ResultHandler

class PermissionsUtils {
    /** 需要申请权限的Activity */
    private var mActivity: Activity? = null

    private var context: Application? = null

    /** 是否正在请求权限 */
    var isRequesting = false
        private set

    private val delegate: PermissionDelegate = PermissionDelegate.create()

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
        context = activity?.application
        return this
    }

    fun getActivity(): Activity? {
        return mActivity
    }

    fun setListener(listener: PermissionsListener?): PermissionsUtils {
        permissionsListener = listener
        return this
    }

    /**
     * 进行权限申请，不带拒绝弹框提示
     *
     * @param applicationContext [Application.getApplicationContext]
     * @param requestType type of request, see [com.fluttercandies.photo_manager.core.utils.RequestTypeUtils]
     * @param permissions A mutable list of permission to request, the method will be modified in the method.
     * @param mediaLocation Whether to request media location permission.
     *
     * @return 返回 [PermissionsUtils] 自身，进行链式调用
     */
    fun requestPermission(
        applicationContext: Context,
        requestType: Int,
        mediaLocation: Boolean,
    ): PermissionsUtils {
        delegate.requestPermission(
            this,
            applicationContext,
            requestType,
            mediaLocation,
        )
        return this
    }

    /**
     * Wrapper for [PermissionChecker.checkCallingOrSelfPermission]
     */
    fun checkCallingOrSelfPermission(permission: String): Boolean {
        if (context == null) {
            throw NullPointerException("Context for the permission request is not exist.")
        }
        return PERMISSION_GRANTED == PermissionChecker.checkCallingOrSelfPermission(
            context!!,
            permission
        )
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
        if (requestCode == PermissionDelegate.requestCode || requestCode == PermissionDelegate.limitedRequestCode) {
            for (i in permissions.indices) {
                LogUtils.info("Returned permissions: " + permissions[i])
                if (grantResults[i] == PackageManager.PERMISSION_DENIED) {
                    deniedPermissionsList.add(permissions[i])
                } else if (grantResults[i] == PackageManager.PERMISSION_GRANTED) {
                    grantedPermissionsList.add(permissions[i])
                }
            }

            LogUtils.debug("dealResult: ")
            LogUtils.debug("  permissions: $permissions")
            LogUtils.debug("  grantResults: $grantResults")
            LogUtils.debug("  deniedPermissionsList: $deniedPermissionsList")
            LogUtils.debug("  grantedPermissionsList: $grantedPermissionsList")

            if (delegate.isHandlePermissionResult()) {
                delegate.handlePermissionResult(
                    this,
                    context!!,
                    permissions,
                    grantResults,
                    needToRequestPermissionsList,
                    deniedPermissionsList,
                    grantedPermissionsList,
                    requestCode,
                )
            } else {
                if (deniedPermissionsList.isNotEmpty()) {
                    // 回调用户拒绝监听
                    permissionsListener!!.onDenied(
                        deniedPermissionsList,
                        grantedPermissionsList,
                        needToRequestPermissionsList
                    )
                } else {
                    // 回调用户同意监听
                    permissionsListener!!.onGranted(needToRequestPermissionsList)
                }
            }
        }
        resetStatus()
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
     *
     */

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

    fun haveLocationPermission(applicationContext: Context): Boolean {
        return delegate.haveMediaLocation(applicationContext)
    }

    fun setNeedToRequestPermissionsList(permission: MutableList<String>) {
        needToRequestPermissionsList.clear()
        needToRequestPermissionsList.addAll(permission)
    }

    fun presentLimited(type: Int, resultHandler: ResultHandler) {
        delegate.presentLimited(this, context!!, type, resultHandler)
    }

    fun getAuthValue(requestType: Int, mediaLocation: Boolean): PermissionResult {
        return delegate.getAuthValue(context!!, requestType, mediaLocation)
    }

}
