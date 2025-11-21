package com.fluttercandies.photo_manager.core

import android.app.Activity
import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.util.LogUtils
import com.fluttercandies.photo_manager.util.ResultHandler
import io.flutter.plugin.common.PluginRegistry

/**
 * Manager for handling write requests (modifications) on Android 11+ (API 30+)
 * Uses MediaStore.createWriteRequest() to request user permission for batch modifications
 */
class PhotoManagerWriteManager(val context: Context, private var activity: Activity?) :
    PluginRegistry.ActivityResultListener {

    fun bindActivity(activity: Activity?) {
        this.activity = activity
    }

    private var androidRWriteRequestCode = 40071
    private var writeHandler: ResultHandler? = null
    private var pendingOperation: WriteOperation? = null

    private val cr: ContentResolver
        get() = context.contentResolver

    /**
     * Represents a pending write operation that will be executed after user grants permission
     */
    private data class WriteOperation(
        val uris: List<Uri>,
        val targetPath: String,
        val operationType: OperationType
    )

    enum class OperationType {
        MOVE,       // Move files to another folder
        UPDATE      // Generic update operation
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
        if (requestCode == androidRWriteRequestCode) {
            handleWriteResult(resultCode)
            return true
        }
        return false
    }

    private fun handleWriteResult(resultCode: Int) {
        if (resultCode == Activity.RESULT_OK) {
            // User granted permission, execute the pending operation
            val operation = pendingOperation
            if (operation != null) {
                val success = when (operation.operationType) {
                    OperationType.MOVE -> performMove(operation.uris, operation.targetPath)
                    OperationType.UPDATE -> performUpdate(operation.uris, operation.targetPath)
                }
                writeHandler?.reply(success)
            } else {
                LogUtils.error("No pending operation found after write permission granted")
                writeHandler?.reply(false)
            }
        } else {
            // User denied permission
            LogUtils.info("User denied write permission")
            writeHandler?.reply(false)
        }
        
        // Clean up
        pendingOperation = null
        writeHandler = null
    }

    /**
     * Request permission to move assets to a different album/folder on Android 11+ (API 30+)
     * 
     * @param uris List of content URIs to move
     * @param targetPath Target RELATIVE_PATH (e.g., "Pictures/MyAlbum")
     * @param resultHandler Callback with result (true if successful, false otherwise)
     */
    @RequiresApi(Build.VERSION_CODES.R)
    fun moveToPathWithPermission(uris: List<Uri>, targetPath: String, resultHandler: ResultHandler) {
        if (activity == null) {
            LogUtils.error("Activity is null, cannot request write permission")
            resultHandler.reply(false)
            return
        }

        this.writeHandler = resultHandler
        this.pendingOperation = WriteOperation(uris, targetPath, OperationType.MOVE)

        try {
            val pendingIntent = MediaStore.createWriteRequest(cr, uris)
            activity?.startIntentSenderForResult(
                pendingIntent.intentSender,
                androidRWriteRequestCode,
                null,
                0,
                0,
                0
            )
        } catch (e: Exception) {
            LogUtils.error("Failed to create write request", e)
            resultHandler.reply(false)
            pendingOperation = null
            writeHandler = null
        }
    }

    /**
     * Perform the actual move operation after permission is granted
     * Updates the RELATIVE_PATH of each URI to move files to a different folder
     */
    private fun performMove(uris: List<Uri>, targetPath: String): Boolean {
        return try {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.RELATIVE_PATH, targetPath)
            }

            var successCount = 0
            for (uri in uris) {
                try {
                    val updated = cr.update(uri, values, null, null)
                    if (updated > 0) {
                        successCount++
                    }
                } catch (e: Exception) {
                    LogUtils.error("Failed to move URI: $uri", e)
                }
            }

            LogUtils.info("Moved $successCount/${uris.size} files to $targetPath")
            successCount > 0  // Return true if at least one file was moved
        } catch (e: Exception) {
            LogUtils.error("Failed to perform move operation", e)
            false
        }
    }

    /**
     * Perform a generic update operation after permission is granted
     * This can be extended for other types of modifications
     */
    private fun performUpdate(uris: List<Uri>, updateData: String): Boolean {
        // Placeholder for generic update operations
        // Can be extended based on specific needs
        LogUtils.info("Generic update operation not yet implemented")
        return false
    }

    /**
     * Request permission to update/modify assets on Android 11+ (API 30+)
     * This is a generic method that can be used for various update operations
     * 
     * @param uris List of content URIs to update
     * @param resultHandler Callback with result (true if permission granted, false otherwise)
     */
    @RequiresApi(Build.VERSION_CODES.R)
    fun requestWritePermission(uris: List<Uri>, resultHandler: ResultHandler) {
        if (activity == null) {
            LogUtils.error("Activity is null, cannot request write permission")
            resultHandler.reply(false)
            return
        }

        this.writeHandler = resultHandler

        try {
            val pendingIntent = MediaStore.createWriteRequest(cr, uris)
            activity?.startIntentSenderForResult(
                pendingIntent.intentSender,
                androidRWriteRequestCode,
                null,
                0,
                0,
                0
            )
        } catch (e: Exception) {
            LogUtils.error("Failed to create write request", e)
            resultHandler.reply(false)
            writeHandler = null
        }
    }
}
