package com.fluttercandies.photo_manager.permission

interface PermissionsListener {
    fun onGranted(needPermissions: MutableList<String>)

    fun onDenied(
        deniedPermissions: MutableList<String>,
        grantedPermissions: MutableList<String>,
        needPermissions: MutableList<String>
    )

    /**
     * Called when the user completes the limited photo selection picker (Android 14+).
     * This allows the app to refresh its asset list after the user modifies their selection.
     */
    fun onLimitedSelectionChanged() {
        // Default empty implementation for backward compatibility
    }
}
