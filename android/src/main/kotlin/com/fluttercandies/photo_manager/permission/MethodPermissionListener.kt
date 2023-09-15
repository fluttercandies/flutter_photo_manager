package com.fluttercandies.photo_manager.permission

import com.fluttercandies.photo_manager.util.ResultHandler

class MethodPermissionListener() : PermissionsListener {

//    fun handleMethod(
//        resultHandler: ResultHandler,
//        onSuccess: (
//            resultHandler: ResultHandler,
//            needLocationPermission: Boolean
//        ) -> Unit
//    ) {
//        val method = resultHandler.call.method
//        requiredPermissions()
//    }

    override fun onGranted() {
        TODO("Not yet implemented")
    }

    override fun onDenied(
        deniedPermissions: MutableList<String>,
        grantedPermissions: MutableList<String>
    ) {
        TODO("Not yet implemented")
    }
}