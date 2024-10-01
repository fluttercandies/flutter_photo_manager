package com.fluttercandies.photo_manager.permission

import android.app.Application
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import com.fluttercandies.photo_manager.core.entity.PermissionResult
import com.fluttercandies.photo_manager.permission.impl.PermissionDelegate19
import com.fluttercandies.photo_manager.permission.impl.PermissionDelegate23
import com.fluttercandies.photo_manager.permission.impl.PermissionDelegate29
import com.fluttercandies.photo_manager.permission.impl.PermissionDelegate33
import com.fluttercandies.photo_manager.permission.impl.PermissionDelegate34
import com.fluttercandies.photo_manager.util.LogUtils
import com.fluttercandies.photo_manager.util.ResultHandler

abstract class PermissionDelegate {
    protected var resultHandler: ResultHandler? = null

    private val tag: String
        get() {
            return this.javaClass.simpleName
        }

    protected fun requestPermission(
        permissionsUtils: PermissionsUtils,
        permission: MutableList<String>,
        requestCode: Int = PermissionDelegate.requestCode
    ) {
        val activity = permissionsUtils.getActivity()
            ?: throw NullPointerException("Activity for the permission request is not exist.")

        permissionsUtils.setNeedToRequestPermissionsList(permission)
        ActivityCompat.requestPermissions(activity, permission.toTypedArray(), requestCode)

        LogUtils.debug("requestPermission: $permission for code $requestCode")
    }

    /**
     * Check if the permission is in the manifest.
     */
    protected fun havePermissionInManifest(context: Context, permission: String): Boolean {
        val applicationInfo = context.applicationInfo
        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.packageManager.getPackageInfo(
                applicationInfo.packageName,
                PackageManager.PackageInfoFlags.of(PackageManager.GET_PERMISSIONS.toLong())
            )
        } else {
            context.packageManager.getPackageInfo(
                applicationInfo.packageName,
                PackageManager.GET_PERMISSIONS
            )
        }
        return packageInfo.requestedPermissions?.contains(permission) == true
    }

    /**
     * Check if the permission is granted for the user.
     */
    protected fun havePermissionForUser(context: Context, permission: String): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            permission
        ) == PackageManager.PERMISSION_GRANTED
    }

    protected fun havePermissionsForUser(context: Context, vararg permissions: String): Boolean {
        return permissions.all { havePermissionForUser(context, it) }
    }

    protected fun haveAnyPermissionForUser(context: Context, vararg permissions: String): Boolean {
        return permissions.any { havePermissionForUser(context, it) }
    }

    /**
     * Check if the permission is granted for the user and it is in the manifest.
     */
    fun havePermission(context: Context, permission: String): Boolean {
        return havePermissionInManifest(context, permission) && havePermissionForUser(
            context,
            permission
        )
    }

    /**
     * Check if the [permission] are granted for the user and it is in the manifest.
     */
    fun havePermissions(context: Context, vararg permission: String): Boolean {
        val result = permission.all { havePermission(context, it) }
        LogUtils.debug("[$tag] havePermissions: ${permission.toList()}, result: $result")
        return result
    }

    /**
     * Request permission.
     *
     * The [permissionsUtils] is used to get the activity.
     * The [context] is used to check the permission is in the manifest.
     * The [requestType] is passed from the dart code.
     * The [mediaLocation] is passed from the dart code.
     */
    abstract fun requestPermission(
        permissionsUtils: PermissionsUtils,
        context: Context,
        requestType: Int,
        mediaLocation: Boolean,
    )

    /**
     * Check if the [requestType] is granted for the user and it is in the manifest.
     */
    abstract fun havePermissions(context: Context, requestType: Int): Boolean

    /**
     * Check if the [mediaLocation] is granted for the user and it is in the manifest.
     */
    abstract fun haveMediaLocation(context: Context): Boolean

    companion object {
        const val requestCode = 3001
        const val limitedRequestCode = 3002

        /**
         * Create a [PermissionDelegate] by the sdk version.
         */
        fun create(): PermissionDelegate {
            return when (Build.VERSION.SDK_INT) {
                in 1 until 23 -> PermissionDelegate19()
                in 23 until 29 -> PermissionDelegate23()
                in 29 until 33 -> PermissionDelegate29()
                33 -> PermissionDelegate33()
                in 34 until Int.MAX_VALUE -> PermissionDelegate34()
                else -> throw UnsupportedOperationException(
                    "This sdk version is not supported yet."
                )
            }
        }
    }

    open fun isHandlePermissionResult(): Boolean {
        return false
    }

    open fun handlePermissionResult(
        permissionsUtils: PermissionsUtils,
        context: Context,
        permissions: Array<String>,
        grantResults: IntArray,
        needToRequestPermissionsList: MutableList<String>,
        deniedPermissionsList: MutableList<String>,
        grantedPermissionsList: MutableList<String>,
        requestCode: Int
    ) {
        throw UnsupportedOperationException(
            "handlePermissionResult is not implemented," +
                    " please implement it in your delegate."
        )
    }

    open fun presentLimited(
        permissionsUtils: PermissionsUtils,
        context: Application,
        type: Int,
        resultHandler: ResultHandler
    ) {
        LogUtils.debug("[$tag] presentLimited is not implemented")
        resultHandler.reply(null)
    }

    abstract fun getAuthValue(
        context: Application,
        requestType: Int,
        mediaLocation: Boolean
    ): PermissionResult
}
