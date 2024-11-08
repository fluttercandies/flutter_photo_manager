package com.fluttercandies.photo_manager.permission.impl

import android.Manifest
import android.app.Application
import android.content.Context
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.core.entity.PermissionResult
import com.fluttercandies.photo_manager.core.utils.RequestTypeUtils
import com.fluttercandies.photo_manager.permission.PermissionDelegate
import com.fluttercandies.photo_manager.permission.PermissionsUtils
import com.fluttercandies.photo_manager.util.LogUtils
import com.fluttercandies.photo_manager.util.ResultHandler

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
        if (havePermissions(
                context,
                requestType
            ) && (!mediaLocation || haveMediaLocation(context))
        ) {
            permissionsUtils.permissionsListener?.onGranted(mutableListOf())
            return
        }

        val permissions = mutableListOf<String>()

        val containsImage = RequestTypeUtils.containsImage(requestType)
        val containsVideo = RequestTypeUtils.containsVideo(requestType)
        val containsAudio = RequestTypeUtils.containsAudio(requestType)

        if (containsImage || containsVideo) {
            permissions.add(mediaImage)
            permissions.add(mediaVideo)
            permissions.add(mediaVisualUserSelected)

            if (mediaLocation) {
                permissions.add(mediaLocationPermission)
            }
        }

        if (containsAudio) {
            permissions.add(mediaAudio)
        }

        if (havePermissions(context, *permissions.toTypedArray())) {
            permissionsUtils.permissionsListener?.onGranted(permissions)
        } else {
            requestPermission(permissionsUtils, permissions)
        }
    }

    override fun havePermissions(context: Context, requestType: Int): Boolean {
        val containsImage = RequestTypeUtils.containsImage(requestType)
        val containsVideo = RequestTypeUtils.containsVideo(requestType)
        val containsAudio = RequestTypeUtils.containsAudio(requestType)

        var granted = true

        if (containsImage || containsVideo) {
            var hasPermission = havePermission(context, mediaImage)
            hasPermission = hasPermission || havePermission(context, mediaVideo)
            hasPermission = hasPermission || havePermission(context, mediaVisualUserSelected)
            granted = granted && hasPermission
        }

        if (containsAudio) {
            granted = granted && havePermission(context, mediaAudio)
        }

        return granted
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
        grantedPermissionsList: MutableList<String>,
        requestCode: Int
    ) {
        if (requestCode == limitedRequestCode) {
            val handler = resultHandler ?: return
            resultHandler = null
            handler.reply(1)
            return
        }

        val needImage = needToRequestPermissionsList.contains(mediaImage)
        val needVideo = needToRequestPermissionsList.contains(mediaVideo)
        val needAudio = needToRequestPermissionsList.contains(mediaAudio)
        val needMediaLocation = needToRequestPermissionsList.contains(mediaLocationPermission)
        val needMediaVisualUserSelected =
            needToRequestPermissionsList.contains(mediaVisualUserSelected)

        var granted = true

        if (needImage || needVideo || needMediaVisualUserSelected) {
            val haveVideoOrImagePermission = haveAnyPermissionForUser(
                context,
                mediaVisualUserSelected, mediaImage, mediaVideo
            )
            granted = haveVideoOrImagePermission
        }

        if (needAudio) {
            granted = granted && havePermission(context, mediaAudio)
        }

        if (needMediaLocation) {
            granted = granted && havePermissionForUser(context, mediaLocationPermission)
        }

        val listener = permissionsUtils.permissionsListener ?: return

        if (granted) {
            listener.onGranted(needToRequestPermissionsList)
        } else {
            listener.onDenied(
                deniedPermissionsList,
                grantedPermissionsList,
                needToRequestPermissionsList
            )
        }
    }

    override fun presentLimited(
        permissionsUtils: PermissionsUtils,
        context: Application,
        type: Int,
        resultHandler: ResultHandler
    ) {
        this.resultHandler = resultHandler

        val permissions = mutableListOf<String>()
        if (RequestTypeUtils.containsImage(type) || RequestTypeUtils.containsVideo(type)) {
            permissions.add(mediaImage)
            permissions.add(mediaVideo)
            permissions.add(mediaVisualUserSelected)
        }

        requestPermission(permissionsUtils, permissions, limitedRequestCode)
    }

    override fun getAuthValue(
        context: Application,
        requestType: Int,
        mediaLocation: Boolean
    ): PermissionResult {
        var result = PermissionResult.NotDetermined

        fun changeResult(newResult: PermissionResult) {
            if (result == PermissionResult.NotDetermined) {
                result = newResult
                return
            }

            when (result) {
                PermissionResult.Denied -> {
                    if (newResult == PermissionResult.Limited || newResult == PermissionResult.Authorized) {
                        result = PermissionResult.Limited
                    }
                }

                PermissionResult.Authorized -> {
                    if (newResult == PermissionResult.Limited || newResult == PermissionResult.Denied) {
                        result = PermissionResult.Limited
                    }
                }

                PermissionResult.Limited -> result = PermissionResult.Limited

                else -> {}
            }
        }

        val containsImage = RequestTypeUtils.containsImage(requestType)
        val containsVideo = RequestTypeUtils.containsVideo(requestType)
        val containsAudio = RequestTypeUtils.containsAudio(requestType)

        if (containsAudio) {
            val audioResult = if (havePermissions(context, mediaAudio)) {
                PermissionResult.Authorized
            } else {
                PermissionResult.Denied
            }

            changeResult(audioResult)
        }

        if (containsVideo) {
            val videoResult = if (havePermissions(context, mediaVideo)) {
                PermissionResult.Authorized
            } else if (havePermissionForUser(context, mediaVisualUserSelected)) {
                PermissionResult.Limited
            } else {
                PermissionResult.Denied
            }

            changeResult(videoResult)
        }

        if (containsImage) {
            val imageResult = if (havePermissions(context, mediaImage)) {
                PermissionResult.Authorized
            } else if (havePermissionForUser(context, mediaVisualUserSelected)) {
                PermissionResult.Limited
            } else {
                PermissionResult.Denied
            }

            changeResult(imageResult)
        }

        return result
    }
}
