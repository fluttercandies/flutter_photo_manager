package com.fluttercandies.photo_manager

import com.fluttercandies.photo_manager.permission.PermissionsUtils
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import com.fluttercandies.photo_manager.core.PhotoManagerPlugin as InnerPhotoManagerPlugin

class PhotoManagerPlugin : FlutterPlugin, ActivityAware {
    private var plugin: InnerPhotoManagerPlugin? = null
    private val permissionsUtils = PermissionsUtils()

    private var binding: ActivityPluginBinding? = null
    private var requestPermissionsResultListener: RequestPermissionsResultListener? = null

    companion object {
        fun register(plugin: InnerPhotoManagerPlugin, messenger: BinaryMessenger) {
            MethodChannel(messenger, "com.fluttercandies/photo_manager").apply {
                setMethodCallHandler(plugin)
            }
        }

        fun createAddRequestPermissionsResultListener(permissionsUtils: PermissionsUtils): RequestPermissionsResultListener {
            return RequestPermissionsResultListener { id, permissions, grantResults ->
                permissionsUtils.dealResult(id, permissions, grantResults)
                false
            }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        plugin = InnerPhotoManagerPlugin(
            binding.applicationContext,
            binding.binaryMessenger,
            null,
            permissionsUtils
        ).apply {
            register(this, binding.binaryMessenger)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        plugin = null
    }

    override fun onDetachedFromActivity() {
        binding?.let {
            onRemoveRequestPermissionResultListener(it)
        }
        // Release the Activity reference on detached.
        plugin?.bindActivity(null)
        binding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityAttached(binding)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityAttached(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        plugin?.bindActivity(null)
    }

    private fun activityAttached(binding: ActivityPluginBinding) {
        this.binding?.apply {
            onRemoveRequestPermissionResultListener(this)
        }
        binding.apply {
            this@PhotoManagerPlugin.binding = this
            plugin?.bindActivity(activity)
            addRequestPermissionsResultListener(this)
        }
    }

    private fun addRequestPermissionsResultListener(binding: ActivityPluginBinding) {
        val listener = createAddRequestPermissionsResultListener(permissionsUtils)
        requestPermissionsResultListener = listener
        binding.addRequestPermissionsResultListener(listener)
        plugin?.let {
            binding.addActivityResultListener(it.deleteManager)
        }
    }

    private fun onRemoveRequestPermissionResultListener(oldBinding: ActivityPluginBinding) {
        requestPermissionsResultListener?.let { listener ->
            oldBinding.removeRequestPermissionsResultListener(listener)
        }
        plugin?.let { p ->
            oldBinding.removeActivityResultListener(p.deleteManager)
        }
    }
}
