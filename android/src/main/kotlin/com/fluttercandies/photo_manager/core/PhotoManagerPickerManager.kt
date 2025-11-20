package com.fluttercandies.photo_manager.core

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.core.utils.ConvertUtils
import com.fluttercandies.photo_manager.util.ResultHandler
import io.flutter.plugin.common.PluginRegistry

class PhotoManagerPickerManager(val context: Context) :
    PluginRegistry.ActivityResultListener {

    var activity: Activity? = null
    private val photoManager = PhotoManager(context)

    fun bindActivity(activity: Activity?) {
        this.activity = activity
    }

    private val requestCode = 40072

    private var resultHandler: ResultHandler? = null

    @RequiresApi(Build.VERSION_CODES.R)
    fun launchPicker(activity: Activity, maxCount: Int, type: Int, resultHandler: ResultHandler) {
        this.resultHandler = resultHandler

        // Create intent to launch photo picker
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
                // Common (both images and videos)
                // Don't set type to allow both
            }
        }

        try {
            activity.startActivityForResult(intent, requestCode)
        } catch (e: Exception) {
            resultHandler.replyError("Failed to launch picker: ${e.message}")
            this.resultHandler = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != this.requestCode) {
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
        
        // Check if multiple items were selected
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
