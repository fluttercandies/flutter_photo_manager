package com.fluttercandies.photo_manager.core

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import androidx.core.app.ComponentActivity
import com.fluttercandies.photo_manager.util.LogUtils
import com.fluttercandies.photo_manager.util.ResultHandler
import io.flutter.plugin.common.PluginRegistry

class PhotoManagerFavoriteManager(val context: Context) :
    PluginRegistry.ActivityResultListener {

    var activity: Activity? = null

    fun bindActivity(activity: Activity?) {
        this.activity = activity
    }

    private val requestCode = 40071

    private var resultHandler: ResultHandler? = null

    private val cr: ContentResolver
        get() = context.contentResolver

    fun favoriteAsset(assetUri: Uri, isFavorite: Boolean, resultHandler: ResultHandler) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            LogUtils.error("IS_FAVORITE is only supported on Android ${Build.VERSION_CODES.R} or above, but current version is ${Build.VERSION.SDK_INT}.")
            resultHandler.reply(false)
            return
        }
        try {
            val result = updateIsFavorite(assetUri, isFavorite)
            resultHandler.reply(result)
        } catch (e: Exception) {
            if (e is RecoverableSecurityException) {
                this.resultHandler = resultHandler

                val pi = MediaStore.createFavoriteRequest(
                    context.contentResolver,
                    setOf(assetUri), isFavorite
                )
                val comAct = activity as? ComponentActivity
                activity?.startIntentSenderForResult(
                    pi.intentSender,
                    requestCode,
                    null,
                    0,
                    0,
                    0
                )
            } else {
                LogUtils.error("favorite assets error", e)
                resultHandler.reply(false)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
        if (requestCode != this.requestCode)
            return false

        resultHandler?.reply(resultCode == Activity.RESULT_OK)
        resultHandler = null
        return true

    }


    @RequiresApi(Build.VERSION_CODES.R)
    private fun updateIsFavorite(assetUri: Uri, isFavorite: Boolean): Boolean {
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.IS_FAVORITE, if (isFavorite) 1 else 0)
        }
        val count = cr.update(assetUri, contentValues, null, null)
        return count > 0
    }
}
