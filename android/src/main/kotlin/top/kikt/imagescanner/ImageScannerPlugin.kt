package top.kikt.imagescanner

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.Registrar
import top.kikt.imagescanner.core.PhotoManagerPlugin
import top.kikt.imagescanner.old.refresh.RefreshObserver

class ImageScannerPlugin(val registrar: Registrar) {
    companion object {
        private val notifyChangeObserver = RefreshObserver()

        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {
            val newChannel = MethodChannel(registrar.messenger(), "top.kikt/photo_manager")
            newChannel.setMethodCallHandler(PhotoManagerPlugin(registrar))
        }
    }
}

data class Asset(val path: String, val imgId: String, val dir: String, val dirId: String, val title: String, var thumb: String?, val type: AssetType, val timeStamp: Long, val duration: Long?, val width: Int, val height: Int) {

    override fun equals(other: Any?): Boolean {
        if (other === this) {
            return true
        }
        if (other !is Asset) return false

        return this.imgId == other.imgId
    }

    override fun hashCode(): Int {
        return imgId.hashCode()
    }

}

enum class AssetType {
    Other,
    Image,
    Video,
}