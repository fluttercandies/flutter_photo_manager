package top.kikt.imagescanner.core.cache

import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import java.io.File
import java.io.FileOutputStream

/// create 2019-09-10 by cai


class AndroidQCache {

    fun clearCache(context: Context) {
        val file = File(getCachePath(context))
        if (file.exists() && file.isDirectory) {
            file.listFiles()?.forEach {
                it?.deleteRecursively()
            }
        }
    }

    private fun getCachePath(context: Context): String = "$context.cacheDir/photo_manager"


    @RequiresApi(Build.VERSION_CODES.Q)
    fun getCacheFile(context: Context, assetId: String, extName: String): File {
        val name = "${assetId}_$extName"

        val targetFile = File(context.cacheDir, name)

        if (targetFile.exists()) {
            return targetFile
        }

        val contentResolver = context.contentResolver
        val uri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, assetId)
        val inputStream = contentResolver.openInputStream(uri)
        val outputStream = FileOutputStream(targetFile)
        outputStream.use {
            inputStream?.copyTo(it)
        }
        return targetFile
    }
}