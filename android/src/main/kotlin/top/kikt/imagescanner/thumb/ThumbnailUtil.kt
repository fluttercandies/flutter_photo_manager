package top.kikt.imagescanner.thumb

import android.content.Context
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import com.bumptech.glide.Glide
import com.bumptech.glide.request.transition.Transition
import io.flutter.plugin.common.MethodChannel
import top.kikt.imagescanner.Asset
import top.kikt.imagescanner.old.ResultHandler
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Created by debuggerx on 18-9-27 下午2:08
 */
object ThumbnailUtil {

    fun getThumbnailByGlide(ctx: Context, path: String, width: Int, height: Int, result: MethodChannel.Result?) {
        val resultHandler = ResultHandler(result)

        Glide.with(ctx)
                .asBitmap()
                .load(File(path))
                .into(object : BitmapTarget(width, height) {
                    override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
                        super.onResourceReady(resource, transition)
                        val bos = ByteArrayOutputStream()
                        resource.compress(Bitmap.CompressFormat.JPEG, 100, bos)
                        resultHandler.reply(bos.toByteArray())
                    }

                    override fun onLoadCleared(placeholder: Drawable?) {
                        resultHandler.reply(null)
                    }

                    override fun onLoadFailed(errorDrawable: Drawable?) {
                        resultHandler.reply(null)
                    }
                })
    }

    fun getThumbnailWithVideo(ctx: Context, asset: Asset, width: Int, height: Int, result: MethodChannel.Result?) {
        val resultHandler = ResultHandler(result)

        Glide.with(ctx)
                .asBitmap()
                .load(File(asset.path))
                .into(object : BitmapTarget(width, height) {
                    override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
                        super.onResourceReady(resource, transition)
                        val bos = ByteArrayOutputStream()
                        resource.compress(Bitmap.CompressFormat.JPEG, 100, bos)
                        resultHandler.reply(bos.toByteArray())
                    }

                    override fun onLoadCleared(placeholder: Drawable?) {
                        resultHandler.reply(null)
                    }
                })
    }

    fun getThumb(ctx: Context, path: String, width: Int, height: Int, callback: (ByteArray?) -> Unit) {

        Glide.with(ctx)
                .asBitmap()
                .load(File(path))
                .into(object : BitmapTarget(width, height) {
                    override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
                        super.onResourceReady(resource, transition)
                        val bos = ByteArrayOutputStream()
                        resource.compress(Bitmap.CompressFormat.JPEG, 100, bos)
                        callback(bos.toByteArray())
                    }

                    override fun onLoadCleared(placeholder: Drawable?) {
                        callback(null)
                    }
                })
    }

    fun getThumb(ctx: Context, bitmap: Bitmap?, width: Int, height: Int, callback: (ByteArray?) -> Unit) {
        Glide.with(ctx)
                .asBitmap()
                .load(bitmap)
                .into(object : BitmapTarget(width, height) {
                    override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
                        super.onResourceReady(resource, transition)
                        val bos = ByteArrayOutputStream()
                        resource.compress(Bitmap.CompressFormat.JPEG, 100, bos)
                        callback(bos.toByteArray())
                    }

                    override fun onLoadCleared(placeholder: Drawable?) {
                        callback(null)
                    }
                })
    }


}
