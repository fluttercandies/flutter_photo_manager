package top.kikt.imagescanner

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import top.kikt.imagescanner.core.PhotoManagerPlugin
import top.kikt.imagescanner.permission.PermissionsUtils

class ImageScannerPlugin: FlutterPlugin, ActivityAware {
  private var plugin: PhotoManagerPlugin? = null
  private val permissionsUtils = PermissionsUtils()

  companion object {
    fun register(plugin: PhotoManagerPlugin, messenger: BinaryMessenger) {
      val newChannel = MethodChannel(messenger, "top.kikt/photo_manager")
      newChannel.setMethodCallHandler(plugin)
    }

    @JvmStatic
    fun registerWith(registrar: Registrar): Unit {
      val permissionsUtils = PermissionsUtils()
      registrar.addRequestPermissionsResultListener(createAddRequestPermissionsResultListener(permissionsUtils))
      val plugin = PhotoManagerPlugin(registrar.context(), registrar.messenger(), registrar.activity(), permissionsUtils)
      register(plugin, registrar.messenger())
    }

    fun createAddRequestPermissionsResultListener(permissionsUtils: PermissionsUtils): RequestPermissionsResultListener {
      return RequestPermissionsResultListener { id, permissions, grantResults ->
        permissionsUtils.dealResult(id, permissions, grantResults)
        false
      }
    }
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    plugin = PhotoManagerPlugin(binding.applicationContext, binding.binaryMessenger, null, permissionsUtils)
    register(plugin!!, binding.binaryMessenger)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
  }

  override fun onDetachedFromActivity() {
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    plugin?.activity = binding.activity
    binding.addRequestPermissionsResultListener(createAddRequestPermissionsResultListener(permissionsUtils))
  }

  override fun onDetachedFromActivityForConfigChanges() {
  }
}

enum class AssetType {
  Image,
  Video,
  Audio,
}