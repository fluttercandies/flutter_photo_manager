package com.fluttercandies.photo_manager.permission.impl

import android.Manifest
import android.app.Application
import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.core.entity.PermissionResult
import com.fluttercandies.photo_manager.permission.PermissionDelegate
import com.fluttercandies.photo_manager.permission.PermissionsUtils

@RequiresApi(Build.VERSION_CODES.Q)
class PermissionDelegate29 : PermissionDelegate() {

    companion object {
        private const val readPermission = Manifest.permission.READ_EXTERNAL_STORAGE
        private const val mediaLocationPermission = Manifest.permission.ACCESS_MEDIA_LOCATION
    }

    override fun requestPermission(
        permissionsUtils: PermissionsUtils,
        context: Context,
        requestType: Int,
        mediaLocation: Boolean
    ) {
        val permissions = mutableListOf(readPermission)

        if (mediaLocation) {
            permissions.add(mediaLocationPermission)
        }

        if (havePermissions(context, *permissions.toTypedArray())) {
            permissionsUtils.permissionsListener?.onGranted(permissions)
        } else {
            requestPermission(permissionsUtils, permissions)
        }
    }

    override fun havePermissions(context: Context, requestType: Int): Boolean {
        return havePermission(context, readPermission)
    }

    override fun haveMediaLocation(context: Context): Boolean {
        return havePermission(context, mediaLocationPermission)
    }

    override fun getAuthValue(
        context: Application,
        requestType: Int,
        mediaLocation: Boolean
    ): PermissionResult {
        return if (havePermissions(context, readPermission)) {
            PermissionResult.Authorized
        } else {
            PermissionResult.Denied
        }
    }
}
