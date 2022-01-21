package com.fluttercandies.photo_manager.permission

interface PermissionsListener {
    fun onGranted()
    fun onDenied(deniedPermissions: MutableList<String>, grantedPermissions: MutableList<String>)
}