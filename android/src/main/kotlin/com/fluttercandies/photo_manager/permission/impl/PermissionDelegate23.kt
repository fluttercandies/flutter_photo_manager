package com.fluttercandies.photo_manager.permission.impl

import android.Manifest
import android.app.Application
import android.content.Context
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.core.entity.PermissionResult
import com.fluttercandies.photo_manager.permission.PermissionsUtils

@RequiresApi(23)
open class PermissionDelegate23 : com.fluttercandies.photo_manager.permission.PermissionDelegate() {

    companion object {
        private const val readPermission = Manifest.permission.READ_EXTERNAL_STORAGE
        private const val writePermission = Manifest.permission.WRITE_EXTERNAL_STORAGE
    }

    override fun requestPermission(
        permissionsUtils: PermissionsUtils,
        context: Context,
        requestType: Int,
        mediaLocation: Boolean
    ) {
        val permissions = mutableListOf(readPermission, writePermission)

        if (havePermission(context, readPermission) && havePermission(context, writePermission)) {
            permissionsUtils.permissionsListener?.onGranted(permissions)
        } else {
            requestPermission(permissionsUtils, permissions)
        }
    }

    override fun havePermissions(context: Context, requestType: Int): Boolean {
        return havePermission(context, readPermission) && havePermission(context, writePermission)
    }

    override fun haveMediaLocation(context: Context): Boolean {
        return true
    }

    override fun getAuthValue(
        context: Application,
        requestType: Int,
        mediaLocation: Boolean
    ): PermissionResult {
        if (havePermissions(context, readPermission, writePermission)) {
            return PermissionResult.Authorized
        } else {
            return PermissionResult.Denied
        }
    }
}