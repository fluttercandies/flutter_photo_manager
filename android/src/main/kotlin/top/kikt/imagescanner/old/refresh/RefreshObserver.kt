package top.kikt.imagescanner.old.refresh

import android.database.ContentObserver
import android.os.Handler
import android.provider.MediaStore
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry


/// create 2019/2/26 by cai


class RefreshObserver(private val handler: Handler = Handler()) : ContentObserver(handler) {

    private var channel: MethodChannel? = null

    fun initWith(registrar: PluginRegistry.Registrar) {
        val photoUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val videoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val resolver = registrar.activity().contentResolver

        channel = MethodChannel(registrar.messenger(), "photo_manager/notify")

        resolver.registerContentObserver(photoUri, false, this)
        resolver.registerContentObserver(videoUri, false, this)
    }

    override fun onChange(selfChange: Boolean) {
        super.onChange(selfChange)
        channel?.invokeMethod("change", 1)
    }

}