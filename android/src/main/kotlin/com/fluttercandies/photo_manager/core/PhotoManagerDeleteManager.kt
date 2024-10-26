package com.fluttercandies.photo_manager.core

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.core.utils.IDBUtils
import com.fluttercandies.photo_manager.util.LogUtils
import com.fluttercandies.photo_manager.util.ResultHandler
import io.flutter.plugin.common.PluginRegistry
import java.util.LinkedList

class PhotoManagerDeleteManager(val context: Context, private var activity: Activity?) :
    PluginRegistry.ActivityResultListener {

    fun bindActivity(activity: Activity?) {
        this.activity = activity
    }

    private var androidQDeleteRequestCode = 40070
    private val androidQUriMap = mutableMapOf<String, Uri?>()
    private val androidQSuccessIds = mutableListOf<String>()
    private val androidQRemovedIds = mutableListOf<String>()

    @RequiresApi(Build.VERSION_CODES.Q)
    inner class AndroidQDeleteTask(
        val id: String,
        val uri: Uri,
        private val exception: RecoverableSecurityException
    ) {
        fun requestPermission() {
            val intent = Intent().apply {
                data = uri
            }
            activity?.startIntentSenderForResult(
                exception.userAction.actionIntent.intentSender,
                androidQDeleteRequestCode,
                intent,
                0,
                0,
                0
            )
        }

        fun handleResult(resultCode: Int) {
            if (resultCode == Activity.RESULT_OK) {
                androidQSuccessIds.add(id)
            }
            requestAndroidQNextPermission()
        }

    }

    private var waitPermissionQueue = LinkedList<AndroidQDeleteTask>()
    private var currentTask: AndroidQDeleteTask? = null

    private var androidRDeleteRequestCode = 40069

    private val cr: ContentResolver
        get() = context.contentResolver

    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
        if (requestCode == androidRDeleteRequestCode) {
            handleAndroidRDelete(resultCode)
            return true
        }
        if (requestCode == androidQDeleteRequestCode) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                currentTask?.handleResult(resultCode)
            }
            return true
        }
        return false
    }

    private fun handleAndroidRDelete(resultCode: Int) {
        if (resultCode == Activity.RESULT_OK) {
            androidRHandler?.apply {
                val ids = call.argument<List<String>>("ids") ?: return@apply
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
    private var androidQHandler: ResultHandler? = null

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

    private fun findIdByUriInApi29(uri: Uri): String? {
        for (entry in androidQUriMap) {
            if (entry.value == uri) {
                return entry.key
            }
        }
        return null
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun requestAndroidQNextPermission() {
        val task = waitPermissionQueue.poll()

        if (task == null) {
            // all permission is granted or denied
            replyAndroidQDeleteResult()
            return
        }

        currentTask = task
        task.requestPermission()
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    fun deleteJustInApi29(uris: HashMap<String, Uri?>, resultHandler: ResultHandler) {
        this.androidQHandler = resultHandler

        androidQUriMap.clear()
        androidQUriMap.putAll(uris)
        androidQSuccessIds.clear()
        androidQRemovedIds.clear()
        waitPermissionQueue.clear()

        for (entry in uris) {
            val uri = entry.value ?: continue
            val id = entry.key
            try {
                cr.delete(uri, null, null)
                androidQRemovedIds.add(id)
            } catch (e: Exception) {
                // request delete permission
                if (e is RecoverableSecurityException) {
                    val task = AndroidQDeleteTask(id, uri, e)
                    waitPermissionQueue.add(task)
                } else {
                    LogUtils.error("delete assets error in api 29", e)
                    replyAndroidQDeleteResult()
                    return
                }
            }
        }

        requestAndroidQNextPermission()
    }

    private fun replyAndroidQDeleteResult() {
        if (androidQSuccessIds.isNotEmpty()) {
            // execute real delete
            for (id in androidQSuccessIds) {
                val uri = androidQUriMap[id] ?: continue
                cr.delete(uri, null, null)
            }
        }

        androidQHandler?.reply(androidQSuccessIds.toList() + androidQRemovedIds.toList())
        androidQSuccessIds.clear()
        androidQRemovedIds.clear()
        androidQHandler = null
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
