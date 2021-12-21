package com.fluttercandies.photo_manager.thumb

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import com.bumptech.glide.Glide
import com.bumptech.glide.Priority
import com.bumptech.glide.request.FutureTarget
import io.flutter.plugin.common.MethodChannel
import com.fluttercandies.photo_manager.core.entity.ThumbLoadOption
import com.fluttercandies.photo_manager.util.ResultHandler
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Created by debuggerx on 18-9-27 下午2:08
 */
object ThumbnailUtil {
    fun getThumbnailByGlide(
        ctx: Context,
        path: String,
        width: Int,
        height: Int,
        format: Bitmap.CompressFormat,
        quality: Int,
        result: MethodChannel.Result?
    ) {
        val resultHandler = ResultHandler(result)

        try {
            val resource = Glide.with(ctx)
                .asBitmap()
                .load(File(path))
                .priority(Priority.IMMEDIATE)
                .submit(width, height).get()
            val bos = ByteArrayOutputStream()
            resource.compress(format, quality, bos)
            resultHandler.reply(bos.toByteArray())
        } catch (e: Exception) {
            resultHandler.reply(null)
        }
    }

    fun getThumbOfUri(
        context: Context,
        uri: Uri,
        width: Int,
        height: Int,
        format: Bitmap.CompressFormat,
        quality: Int,
        callback: (ByteArray?) -> Unit
    ) {
        try {
            val resource = Glide.with(context)
                .asBitmap()
                .load(uri)
                .priority(Priority.IMMEDIATE)
                .submit(width, height).get()
            val bos = ByteArrayOutputStream()
            resource.compress(format, quality, bos)
            callback(bos.toByteArray())
        } catch (e: Exception) {
            callback(null)
        }
    }

    fun requestCacheThumb(
        context: Context,
        uri: Uri,
        thumbLoadOption: ThumbLoadOption
    ): FutureTarget<Bitmap> {
        return Glide.with(context)
            .asBitmap()
            .priority(Priority.LOW)
            .load(uri)
            .submit(thumbLoadOption.width, thumbLoadOption.height)
    }

    fun requestCacheThumb(
        context: Context,
        path: String,
        thumbLoadOption: ThumbLoadOption
    ): FutureTarget<Bitmap> {
        return Glide.with(context)
            .asBitmap()
            .priority(Priority.LOW)
            .load(path)
            .submit(thumbLoadOption.width, thumbLoadOption.height)
    }

    fun clearCache(context: Context) {
        Glide.get(context).apply {
            clearDiskCache()
        }
    }
}
