package com.fluttercandies.photo_manager.core

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.core.utils.ConvertUtils
import com.fluttercandies.photo_manager.util.ResultHandler
import io.flutter.plugin.common.PluginRegistry

/**
 * Manager for handling native photo picker operations.
 * 
 * On Android 11+ (API 30+), uses the modern Photo Picker API (ACTION_PICK_IMAGES).
 * On older Android versions, falls back to the legacy ACTION_PICK intent.
 * Both approaches work without requiring storage permissions.
 */
class PhotoManagerPickerManager(val context: Context) :
    PluginRegistry.ActivityResultListener {

    var activity: Activity? = null
    private val photoManager = PhotoManager(context)

    fun bindActivity(activity: Activity?) {
        this.activity = activity
    }

    // Request codes for different picker modes
    private val requestCodeModern = 40072  // For Photo Picker API (Android 11+)
    private val requestCodeLegacy = 40073  // For ACTION_PICK (older Android)

    private var resultHandler: ResultHandler? = null

    /**
     * Launch the appropriate picker based on Android version.
     */
    fun launchPicker(activity: Activity, maxCount: Int, type: Int, resultHandler: ResultHandler) {
        this.resultHandler = resultHandler

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ (API 30+): Use modern Photo Picker API
            launchModernPicker(activity, maxCount, type)
        } else {
            // Older Android: Use legacy ACTION_PICK intent
            launchLegacyPicker(activity, type)
        }
    }

    /**
     * Launch the modern Photo Picker API (Android 11+).
     * Uses ACTION_PICK_IMAGES which doesn't require storage permissions.
     */
    @RequiresApi(Build.VERSION_CODES.R)
    private fun launchModernPicker(activity: Activity, maxCount: Int, type: Int) {
        try {
            val intent = Intent(MediaStore.ACTION_PICK_IMAGES)
            
            // Set maximum number of selectable items
            intent.putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, maxCount)
            
            // Set media type filter
            when (type) {
                1 -> {
                    // Images only
                    intent.type = "image/*"
                }
                2 -> {
                    // Videos only
                    intent.type = "video/*"
                }
                else -> {
                    // Common (both images and videos) - don't set type to allow both
                }
            }

            activity.startActivityForResult(intent, requestCodeModern)
        } catch (e: Exception) {
            resultHandler?.replyError("Failed to launch photo picker: ${e.message}")
            this.resultHandler = null
        }
    }

    /**
     * Launch the legacy ACTION_PICK intent (Android < 11).
     * This also works without storage permissions on most devices.
     */
    private fun launchLegacyPicker(activity: Activity, type: Int) {
        try {
            val intent: Intent
            
            when (type) {
                1 -> {
                    // Images only
                    intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
                }
                2 -> {
                    // Videos only
                    intent = Intent(Intent.ACTION_PICK, MediaStore.Video.Media.EXTERNAL_CONTENT_URI)
                }
                else -> {
                    // Common (both images and videos)
                    // Use generic ACTION_PICK with Images URI as base
                    // Note: Legacy picker only supports single selection
                    intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
                }
            }
            
            activity.startActivityForResult(intent, requestCodeLegacy)
        } catch (e: Exception) {
            resultHandler?.replyError("Failed to launch picker: ${e.message}")
            this.resultHandler = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        // Only handle our request codes
        if (requestCode != requestCodeModern && requestCode != requestCodeLegacy) {
            return false
        }

        val handler = resultHandler ?: return false
        resultHandler = null

        if (resultCode != Activity.RESULT_OK) {
            // User cancelled
            handler.reply(mapOf("data" to emptyList<Any>()))
            return true
        }

        // Process selected URIs
        val uris = mutableListOf<Uri>()
        
        if (requestCode == requestCodeModern && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Modern Photo Picker API supports multiple selection
            data?.clipData?.let { clipData ->
                for (i in 0 until clipData.itemCount) {
                    clipData.getItemAt(i)?.uri?.let { uri ->
                        uris.add(uri)
                    }
                }
            } ?: data?.data?.let { uri ->
                // Single item selected
                uris.add(uri)
            }
        } else {
            // Legacy picker only supports single selection
            data?.data?.let { uri ->
                uris.add(uri)
            }
        }

        if (uris.isEmpty()) {
            handler.reply(mapOf("data" to emptyList<Any>()))
            return true
        }

        // Convert URIs to AssetEntity objects in background thread
        PhotoManagerPlugin.runOnBackground {
            val assets = photoManager.getAssetsFromUris(uris)
            val result = ConvertUtils.convertAssets(assets)
            
            // Reply on main thread
            Handler(Looper.getMainLooper()).post {
                handler.reply(mapOf("data" to result))
            }
        }

        return true
    }
}
