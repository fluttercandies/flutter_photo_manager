package top.kikt.imagescanner

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.Registrar
import top.kikt.imagescanner.core.PhotoManagerPlugin

class ImageScannerPlugin(val registrar: Registrar) {
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar): Unit {
      val newChannel = MethodChannel(registrar.messenger(), "top.kikt/photo_manager")
      newChannel.setMethodCallHandler(PhotoManagerPlugin(registrar))
    }
  }
}

enum class AssetType {
  Image,
  Video,
  Audio,
}