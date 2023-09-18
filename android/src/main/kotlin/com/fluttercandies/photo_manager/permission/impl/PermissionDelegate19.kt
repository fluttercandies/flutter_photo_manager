package com.fluttercandies.photo_manager.permission.impl

import android.content.Context
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.permission.PermissionsUtils

class PermissionDelegate19 : com.fluttercandies.photo_manager.permission.PermissionDelegate() {
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
}