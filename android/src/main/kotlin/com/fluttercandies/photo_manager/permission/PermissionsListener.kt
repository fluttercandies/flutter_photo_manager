package com.fluttercandies.photo_manager.permission

interface PermissionsListener {
    fun onGranted(needPermissions: MutableList<String>)

    fun onDenied(
        deniedPermissions: MutableList<String>,
        grantedPermissions: MutableList<String>,
        needPermissions: MutableList<String>
    )
}
