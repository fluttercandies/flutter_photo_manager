package com.fluttercandies.photo_manager.core

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
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

    @RequiresApi(Build.VERSION_CODES.R)
    fun favoriteAsset(assetUri: Uri, isFavorite: Boolean, resultHandler: ResultHandler) {
        this.resultHandler = resultHandler

        val pi = MediaStore.createFavoriteRequest(
            context.contentResolver,
            setOf(assetUri), isFavorite
        )
        activity?.startIntentSenderForResult(
            pi.intentSender,
            requestCode,
            null,
            0,
            0,
            0
        )
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
        if (requestCode != this.requestCode)
            return false

        resultHandler?.reply(resultCode == Activity.RESULT_OK)
        resultHandler = null
        return true

    }

}
