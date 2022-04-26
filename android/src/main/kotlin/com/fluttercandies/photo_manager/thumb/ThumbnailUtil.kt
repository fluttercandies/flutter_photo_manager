package com.fluttercandies.photo_manager.thumb

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import com.bumptech.glide.Glide
import com.bumptech.glide.Priority
import com.bumptech.glide.request.FutureTarget
import com.bumptech.glide.request.RequestOptions
import io.flutter.plugin.common.MethodChannel
import com.fluttercandies.photo_manager.core.entity.ThumbLoadOption
import com.fluttercandies.photo_manager.util.ResultHandler
import java.io.ByteArrayOutputStream
import java.io.File

object ThumbnailUtil {
    fun getThumbnail(
        ctx: Context,
        path: String,
        width: Int,
        height: Int,
        format: Bitmap.CompressFormat,
        quality: Int,
        frame: Long,
        result: MethodChannel.Result?
    ) {
        val resultHandler = ResultHandler(result)

        try {
            val resource = Glide.with(ctx)
                .asBitmap()
                .apply(RequestOptions().frame(frame).priority(Priority.IMMEDIATE))
                .load(File(path))
                .submit(width, height).get()
            val bos = ByteArrayOutputStream()
            resource.compress(format, quality, bos)
            resultHandler.reply(bos.toByteArray())
        } catch (e: Exception) {
            resultHandler.reply(null)
        }
    }

    fun getThumbnail(
        context: Context,
        uri: Uri,
        width: Int,
        height: Int,
        format: Bitmap.CompressFormat,
        quality: Int,
        frame: Long,
        result: MethodChannel.Result?
    ) {
        val resultHandler = ResultHandler(result)

        try {
            val resource = Glide.with(context)
                .asBitmap()
                .apply(RequestOptions().frame(frame).priority(Priority.IMMEDIATE))
                .load(uri)
                .submit(width, height).get()
            val bos = ByteArrayOutputStream()
            resource.compress(format, quality, bos)
            resultHandler.reply(bos.toByteArray())
        } catch (e: Exception) {
            resultHandler.reply(null)
        }
    }

    fun requestCacheThumb(
        context: Context,
        uri: Uri,
        thumbLoadOption: ThumbLoadOption
    ): FutureTarget<Bitmap> {
        return Glide.with(context)
            .asBitmap()
            .apply(RequestOptions().frame(thumbLoadOption.frame).priority(Priority.LOW))
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
            .apply(RequestOptions().frame(thumbLoadOption.frame).priority(Priority.LOW))
            .load(path)
            .submit(thumbLoadOption.width, thumbLoadOption.height)
    }

    fun clearCache(context: Context) {
        Glide.get(context).apply { clearDiskCache() }
    }
}
