package com.fluttercandies.photo_manager.core

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.core.utils.IDBUtils
import com.fluttercandies.photo_manager.util.ResultHandler
import io.flutter.plugin.common.PluginRegistry

class PhotoManagerDeleteManager(val context: Context, private var activity: Activity?) :
    PluginRegistry.ActivityResultListener {

    fun bindActivity(activity: Activity?) {
        this.activity = activity
    }

    private var androidRDeleteRequestCode = 40069

    private val cr: ContentResolver
        get() = context.contentResolver

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == androidRDeleteRequestCode) {
            handleAndroidRDelete(resultCode)
            return true
        }
        return true
    }

    private fun handleAndroidRDelete(resultCode: Int) {
        if (resultCode == Activity.RESULT_OK) {
            androidRHandler?.apply {
                val ids = call?.argument<List<String>>("ids") ?: return@apply
                androidRHandler?.reply(ids)
            }
        } else {
            androidRHandler?.reply(listOf<String>())
        }
    }

    fun deleteInApi28(ids: List<String>) {
        val where = ids.joinToString(",") { "?" }
        cr.delete(
            IDBUtils.allUri,
            "${MediaStore.MediaColumns._ID} in ($where)",
            ids.toTypedArray()
        )
    }
//
//    enum class Action {
//        Delete,
//        Trash,
//    }

    private var androidRHandler: ResultHandler? = null

    @RequiresApi(Build.VERSION_CODES.R)
    fun deleteInApi30(uris: List<Uri?>, resultHandler: ResultHandler) {
        this.androidRHandler = resultHandler
        val pendingIntent = MediaStore.createDeleteRequest(cr, uris.mapNotNull { it })
        activity?.startIntentSenderForResult(
            pendingIntent.intentSender,
            androidRDeleteRequestCode,
            null,
            0,
            0,
            0
        )
    }

    @RequiresApi(Build.VERSION_CODES.R)
    fun moveToTrashInApi30(uris: List<Uri?>, resultHandler: ResultHandler) {
        this.androidRHandler = resultHandler
        val pendingIntent = MediaStore.createTrashRequest(cr, uris.mapNotNull { it }, true)
        activity?.startIntentSenderForResult(
            pendingIntent.intentSender,
            androidRDeleteRequestCode,
            null,
            0,
            0,
            0
        )
    }
}
