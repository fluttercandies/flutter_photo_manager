package top.kikt.imagescanner.core

import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.provider.MediaStore
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/// create 2019-09-09 by cai


class PhotoManagerNotifyChannel(val registry: PluginRegistry.Registrar, handler: Handler) {

    private var notifying = false

    val isNotifying: Boolean
        get() = notifying

    private val videoObserver = VideoObserver(handler)
    private val imageObserver = ImageObserver(handler)

    private val methodChannel = MethodChannel(registry.messenger(), "top.kikt/photo_manager/notify")

    private val context
        get() = registry.context().applicationContext

    fun startNotify() {
        val imageUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val videoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        context.contentResolver.registerContentObserver(imageUri, false, imageObserver)
        context.contentResolver.registerContentObserver(videoUri, false, videoObserver)
        notifying = true
    }

    fun stopNotify() {
        notifying = false
        context.contentResolver.unregisterContentObserver(imageObserver)
        context.contentResolver.unregisterContentObserver(videoObserver)
    }

    fun onOuterChange(selfChange: Boolean, uri: Uri?) {
        methodChannel.invokeMethod("change", mapOf(
                "android-self" to selfChange,
                "android-uri" to uri.toString()
        ))
    }

    fun setAndroidQExperimental(open: Boolean) {
        methodChannel.invokeMethod("setAndroidQExperimental", mapOf("open" to open))
    }

    inner class VideoObserver(handler: Handler) : ContentObserver(handler) {
        override fun onChange(selfChange: Boolean, uri: Uri?) {
            super.onChange(selfChange, uri)
            onOuterChange(selfChange, uri)
        }
    }

    inner class ImageObserver(handler: Handler) : ContentObserver(handler) {
        override fun onChange(selfChange: Boolean, uri: Uri?) {
            super.onChange(selfChange, uri)
            onOuterChange(selfChange, uri)
        }
    }
}

