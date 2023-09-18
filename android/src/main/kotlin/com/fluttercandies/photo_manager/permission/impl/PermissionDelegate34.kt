package com.fluttercandies.photo_manager.permission.impl

import android.Manifest
import android.content.Context
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.core.utils.RequestTypeUtils
import com.fluttercandies.photo_manager.permission.PermissionDelegate
import com.fluttercandies.photo_manager.permission.PermissionsUtils

@RequiresApi(34)
class PermissionDelegate34 : PermissionDelegate() {

    companion object {
        private const val mediaVideo = Manifest.permission.READ_MEDIA_VIDEO
        private const val mediaImage = Manifest.permission.READ_MEDIA_IMAGES
        private const val mediaAudio = Manifest.permission.READ_MEDIA_AUDIO

        private const val mediaVisualUserSelected =
            Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED

        private const val mediaLocationPermission = Manifest.permission.ACCESS_MEDIA_LOCATION
    }


    override fun requestPermission(
        permissionsUtils: PermissionsUtils,
        context: Context,
        requestType: Int,
        mediaLocation: Boolean
    ) {
        var havePermission = true

        val containsImage = RequestTypeUtils.containsImage(requestType)
        val containsVideo = RequestTypeUtils.containsVideo(requestType)
        val containsAudio = RequestTypeUtils.containsAudio(requestType)

        val permissions = mutableListOf<String>()

        if (containsVideo || containsImage) {
            permissions.add(mediaVisualUserSelected)

            // check have media visual user selected permission, the permission does not need to be defined in the manifest.
            val haveMediaVisualUserSelected =
                havePermissionForUser(context, mediaVisualUserSelected)

            havePermission = haveMediaVisualUserSelected

            if (mediaLocation) {
                permissions.add(mediaLocationPermission)
                havePermission = havePermission && havePermission(context, mediaLocationPermission)
            }

            if (containsVideo) {
                permissions.add(mediaVideo)
            }

            if (containsImage) {
                permissions.add(mediaImage)
            }
        }

        if (containsAudio) {
            permissions.add(mediaAudio)
            havePermission = havePermission && havePermission(context, mediaAudio)
        }

        if (havePermission) {
            permissionsUtils.permissionsListener?.onGranted(permissions)
        } else {
            requestPermission(permissionsUtils, permissions)
        }
    }

    override fun havePermissions(context: Context, requestType: Int): Boolean {
        val containsImage = RequestTypeUtils.containsImage(requestType)
        val containsVideo = RequestTypeUtils.containsVideo(requestType)
        val containsAudio = RequestTypeUtils.containsAudio(requestType)

        var result = true

        if (containsVideo || containsImage) {
            result = result && havePermission(context, mediaVisualUserSelected)
        }

        if (containsAudio) {
            result = result && havePermission(context, mediaAudio)
        }

        return result
    }

    override fun haveMediaLocation(context: Context): Boolean {
        return havePermission(context, mediaLocationPermission)
    }

    override fun isHandlePermissionResult() = true

    override fun handlePermissionResult(
        permissionsUtils: PermissionsUtils,
        context: Context,
        permissions: Array<String>,
        grantResults: IntArray,
        needToRequestPermissionsList: MutableList<String>,
        deniedPermissionsList: MutableList<String>,
        grantedPermissionsList: MutableList<String>
    ) {
        val needImage = needToRequestPermissionsList.contains(mediaImage)
        val needVideo = needToRequestPermissionsList.contains(mediaVideo)
        val needAudio = needToRequestPermissionsList.contains(mediaAudio)
        val needMediaLocation = needToRequestPermissionsList.contains(mediaLocationPermission)
        val needMediaVisualUserSelected =
            needToRequestPermissionsList.contains(mediaVisualUserSelected)


    }
}