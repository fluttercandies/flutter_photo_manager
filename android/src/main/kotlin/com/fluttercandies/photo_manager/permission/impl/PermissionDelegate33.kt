package com.fluttercandies.photo_manager.permission.impl

import android.Manifest
import android.app.Application
import android.content.Context
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.core.entity.PermissionResult
import com.fluttercandies.photo_manager.core.utils.RequestTypeUtils
import com.fluttercandies.photo_manager.permission.PermissionDelegate
import com.fluttercandies.photo_manager.permission.PermissionsUtils

@RequiresApi(33)
class PermissionDelegate33 : PermissionDelegate() {
    companion object {
        private const val mediaVideo = Manifest.permission.READ_MEDIA_VIDEO
        private const val mediaImage = Manifest.permission.READ_MEDIA_IMAGES
        private const val mediaAudio = Manifest.permission.READ_MEDIA_AUDIO

        private const val mediaLocationPermission = Manifest.permission.ACCESS_MEDIA_LOCATION
    }

    override fun requestPermission(
        permissionsUtils: PermissionsUtils,
        context: Context,
        requestType: Int,
        mediaLocation: Boolean
    ) {
        val permissions = mutableListOf<String>()

        val containsImage = RequestTypeUtils.containsImage(requestType)
        val containsVideo = RequestTypeUtils.containsVideo(requestType)
        val containsAudio = RequestTypeUtils.containsAudio(requestType)

        if (containsImage || containsVideo) {
            permissions.add(mediaImage)
            permissions.add(mediaVideo)
        }
        if (containsAudio) {
            permissions.add(mediaAudio)
        }
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
        val containsVideo = RequestTypeUtils.containsVideo(requestType)
        val containsImage = RequestTypeUtils.containsImage(requestType)
        val containsAudio = RequestTypeUtils.containsAudio(requestType)

        var granted = true

        if (containsImage) {
            granted = granted && havePermission(context, mediaImage)
        }
        if (containsVideo) {
            granted = granted && havePermission(context, mediaVideo)
        }
        if (containsAudio) {
            granted = granted && havePermission(context, mediaAudio)
        }

        return granted
    }

    override fun haveMediaLocation(context: Context): Boolean {
        return havePermission(context, Manifest.permission.ACCESS_MEDIA_LOCATION)
    }

    override fun getAuthValue(
        context: Application,
        requestType: Int,
        mediaLocation: Boolean
    ): PermissionResult {
        return if (havePermissions(context, requestType)) {
            PermissionResult.Authorized
        } else {
            PermissionResult.Denied
        }
    }
}
