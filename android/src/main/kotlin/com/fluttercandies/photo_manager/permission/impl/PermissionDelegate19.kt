package com.fluttercandies.photo_manager.permission.impl

import android.app.Application
import android.content.Context
import com.fluttercandies.photo_manager.core.entity.PermissionResult
import com.fluttercandies.photo_manager.permission.PermissionDelegate
import com.fluttercandies.photo_manager.permission.PermissionsUtils

class PermissionDelegate19 : PermissionDelegate() {
    override fun requestPermission(
        permissionsUtils: PermissionsUtils,
        context: Context,
        requestType: Int,
        mediaLocation: Boolean
    ) {
        permissionsUtils.permissionsListener?.onGranted(mutableListOf())
    }

    override fun havePermissions(context: Context, requestType: Int): Boolean {
        return true
    }

    override fun haveMediaLocation(context: Context): Boolean {
        return true
    }

    override fun getAuthValue(
        context: Application, requestType: Int, mediaLocation: Boolean
    ): PermissionResult {
        return PermissionResult.Authorized
    }
}
