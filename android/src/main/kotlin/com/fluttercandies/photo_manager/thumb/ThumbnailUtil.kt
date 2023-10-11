package com.fluttercandies.photo_manager.thumb

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import com.bumptech.glide.Glide
import com.bumptech.glide.Priority
import com.bumptech.glide.request.FutureTarget
import com.bumptech.glide.request.RequestOptions
import com.bumptech.glide.signature.ObjectKey
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.entity.ThumbLoadOption
import com.fluttercandies.photo_manager.util.ResultHandler
import java.io.ByteArrayOutputStream

object ThumbnailUtil {
    fun getThumbnail(
        context: Context,
        entity: AssetEntity,
        width: Int,
        height: Int,
        format: Bitmap.CompressFormat,
        quality: Int,
        frame: Long,
        resultHandler: ResultHandler
    ) {
        try {
            val resource = Glide.with(context)
                .asBitmap()
                .apply(RequestOptions().frame(frame).priority(Priority.IMMEDIATE))
                .load(entity.getUri())
                .signature(ObjectKey(entity.modifiedDate))
                .submit(width, height).get()
            val bos = ByteArrayOutputStream()
            resource.compress(format, quality, bos)
            resultHandler.reply(bos.toByteArray())
        } catch (e: Exception) {
            resultHandler.replyError("Thumbnail request error", e.toString())
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
