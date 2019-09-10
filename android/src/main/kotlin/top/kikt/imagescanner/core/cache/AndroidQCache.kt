package top.kikt.imagescanner.core.cache

import android.content.Context
import java.io.File

/// create 2019-09-10 by cai


class AndroidQCache(private val context: Context) {

    private val cachePath = "$context.cacheDir/photo_manager"

    fun clearCache() {
        val file = File(cachePath)
        if (file.exists() && file.isDirectory) {
            file.listFiles()?.forEach {
                it?.deleteRecursively()
            }
        }
    }

    fun getCacheFile(assetId: String, extName: String): File {
        val name = "$assetId.$extName"

        val targetFile = File(name)

        return targetFile

//        if (targetFile.exists()) {
//            return targetFile
//        }
//
//        val contentResolver = context.contentResolver
//        val uri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, assetId)
//        val originalUri = MediaStore.setRequireOriginal(uri)
//        val inputStream = contentResolver.openInputStream(originalUri)
//        inputStream?.copyTo(FileOutputStream(targetFile))
//        return targetFile
    }
}