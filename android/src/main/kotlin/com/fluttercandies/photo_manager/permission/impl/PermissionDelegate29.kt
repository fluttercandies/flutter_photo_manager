package com.fluttercandies.photo_manager.permission.impl

import android.Manifest
import android.app.Application
import android.content.Context
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.core.entity.PermissionResult
import com.fluttercandies.photo_manager.permission.PermissionsUtils

@RequiresApi(29)
class PermissionDelegate29 : PermissionDelegate23() {

    companion object {
        private const val readPermission = Manifest.permission.READ_EXTERNAL_STORAGE
        private const val writePermission = Manifest.permission.WRITE_EXTERNAL_STORAGE
        private const val mediaLocationPermission = Manifest.permission.ACCESS_MEDIA_LOCATION
    }

    override fun requestPermission(
        permissionsUtils: PermissionsUtils,
        context: Context,
        requestType: Int,
        mediaLocation: Boolean
    ) {
        val permissions = mutableListOf(readPermission, writePermission)

        if (mediaLocation) {
            permissions.add(mediaLocationPermission)
        }

        if (havePermissions(context, *permissions.toTypedArray())) {
            permissionsUtils.permissionsListener?.onGranted(permissions)
        } else {
            requestPermission(permissionsUtils, permissions)
        }
    }

    override fun haveMediaLocation(context: Context): Boolean {
        return havePermission(context, Manifest.permission.ACCESS_MEDIA_LOCATION)
    }

    override fun getAuthValue(
        context: Application,
        requestType: Int,
        mediaLocation: Boolean
    ): PermissionResult {
        return if (havePermissions(context, readPermission, writePermission)) {
            PermissionResult.Authorized
        } else {
            PermissionResult.Denied
        }
    }
}