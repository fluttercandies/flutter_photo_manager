package top.kikt.imagescanner.thumb

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Drawable
import android.provider.MediaStore
import android.provider.MediaStore.Video.Thumbnails.MICRO_KIND
import com.bumptech.glide.Glide
import com.bumptech.glide.request.transition.Transition
import io.flutter.plugin.common.MethodChannel
import top.kikt.imagescanner.Img
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Created by debuggerx on 18-9-27 下午2:08
 */
object ThumbnailUtil {

    fun getThumbnailByGlide(ctx: Context, path: String, width: Int, height: Int, result: MethodChannel.Result) {
        var isReply = false
        fun reply(r: Any?) {
            if (isReply) {
                return
            }
            isReply = true
            result.success(r)
        }
        Glide.with(ctx)
                .asBitmap()
                .load(File(path))
                .into(object : CustomTarget<Bitmap>(width, height) {
                    override fun onResourceReady(resource: Bitmap, transition: Transition<in Bitmap>?) {
                        val bos = ByteArrayOutputStream()
                        resource.compress(Bitmap.CompressFormat.JPEG, 100, bos)
                        reply(bos.toByteArray())
                    }

                    override fun onLoadCleared(placeholder: Drawable?) {
                        reply(null)
                    }
                })
    }

    fun getThumbnailWithVideo(activity: Context, img:Img, width: Int, height: Int, result: MethodChannel.Result) {
        var isReply = false
        fun reply(r: Any?) {
            if (isReply) {
                return
            }
            isReply = true
            result.success(r)
        }
        val thumbnail = MediaStore.Video.Thumbnails.getThumbnail(activity.contentResolver, img.imgId.toLong(), MICRO_KIND, BitmapFactory.Options().apply {
            outWidth = width
            outHeight = height
        })
        val bos = ByteArrayOutputStream()
        thumbnail.compress(Bitmap.CompressFormat.JPEG, 100, bos)
        reply(bos.toByteArray())
    }

}
