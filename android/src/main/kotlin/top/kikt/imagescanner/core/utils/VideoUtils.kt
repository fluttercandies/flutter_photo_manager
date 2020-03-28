package top.kikt.imagescanner.core.utils

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Drawable
import android.media.MediaPlayer
import android.util.Size
import android.util.SizeF
import java.util.concurrent.Callable
import java.util.concurrent.CompletableFuture
import java.util.concurrent.Future
import java.util.concurrent.FutureTask

object VideoUtils {

  data class VideoInfo(var width: Int?, var height: Int?, var duration: Int?)

  fun getPropertiesUseMediaPlayer(path: String): VideoInfo {
    val mediaPlayer = MediaPlayer()
    mediaPlayer.setDataSource(path)
    mediaPlayer.setOnErrorListener { mp, what, extra ->
      true
    }
    try {
      mediaPlayer.prepare()
    } catch (e: Throwable) {
      mediaPlayer.release()
      return VideoInfo(null, null, null)
    }
    mediaPlayer.videoHeight
    val info = VideoInfo(mediaPlayer.videoWidth, mediaPlayer.videoHeight, mediaPlayer.duration)

    mediaPlayer.stop()
    mediaPlayer.release()

    return info
  }

  fun getSize(path: String): SizeF {
    val bitmap = BitmapFactory.decodeFile(path)
    return SizeF(bitmap.width.toFloat(), bitmap.height.toFloat())
  }
}