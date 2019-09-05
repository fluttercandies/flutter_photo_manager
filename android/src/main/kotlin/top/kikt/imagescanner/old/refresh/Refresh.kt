package top.kikt.imagescanner.old.refresh

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.ThumbnailUtils
import android.os.Environment.DIRECTORY_PICTURES
import io.flutter.plugin.common.PluginRegistry
import top.kikt.imagescanner.Asset
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream


class ThumbHelper(private val registrar: PluginRegistry.Registrar) {

    private fun makeThumb(path: String, id: String): String {
        val thumbDir = registrar.activeContext()?.getExternalFilesDir(DIRECTORY_PICTURES)?.absolutePath + "/.thumb"
        val file = File(thumbDir).apply {
            mkdir()
        }

        val bitmap = ThumbnailUtils.extractThumbnail(BitmapFactory.decodeFile(path), 100, 100)
        val result = "${file.absolutePath}/$id.jpg"
        val fileOutputStream = FileOutputStream(result)
        bitmap?.compress(Bitmap.CompressFormat.JPEG, 95, fileOutputStream)
        fileOutputStream.close()

        return result
    }

    fun getThumb(path: String, id: String): String {
        val thumbPath = registrar.activeContext()?.getExternalFilesDir(DIRECTORY_PICTURES)?.absolutePath + "/.thumb"
        val thumbFile = File(thumbPath).apply {
            mkdir()
        }
        val result = "${thumbFile.absolutePath}/$id.jpg"

        if (File(result).exists()) {
            return result
        }
        return makeThumb(path, id)
    }

    fun getThumbData(asset: Asset): ByteArray {
        val bitmap = ThumbnailUtils.extractThumbnail(BitmapFactory.decodeFile(asset.path), 80, 80)
        val bos = ByteArrayOutputStream()
        bitmap?.compress(Bitmap.CompressFormat.JPEG, 95, bos)
        return bos.toByteArray()
    }
}