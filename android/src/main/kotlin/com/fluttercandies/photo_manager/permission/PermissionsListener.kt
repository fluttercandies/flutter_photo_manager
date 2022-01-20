package com.fluttercandies.photo_manager.permission

interface PermissionsListener {
    fun onDenied(deniedPermissions: List<String>, grantedPermissions: List<String>)
    fun onGranted()
}