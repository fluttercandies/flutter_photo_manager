package com.fluttercandies.photo_manager.core.cache

import android.content.Context
import android.net.Uri
import android.os.Build
import androidx.annotation.RequiresApi
import com.fluttercandies.photo_manager.core.entity.AssetEntity
import com.fluttercandies.photo_manager.core.utils.AndroidQDBUtils
import com.fluttercandies.photo_manager.core.utils.AndroidQDBUtils.throwIdNotFound
import com.fluttercandies.photo_manager.util.LogUtils
import java.io.File
import java.io.FileOutputStream

@RequiresApi(Build.VERSION_CODES.Q)
class ScopedCache {
    companion object {
        private const val FILENAME_PREFIX = "pm_"
    }

    fun getCacheFileFromEntity(
        context: Context,
        assetEntity: AssetEntity,
        isOrigin: Boolean
    ): File {
        val assetId = assetEntity.id
        val targetFile = getCacheFile(context, assetEntity, isOrigin)
        if (targetFile.exists()) {
            return targetFile
        }
        val contentResolver = context.contentResolver
        val uri = AndroidQDBUtils.getUri(assetId, assetEntity.type, isOrigin)
        if (uri == Uri.EMPTY) {
            throwIdNotFound(assetId)
        }
        try {
            LogUtils.info(
                "Caching $assetId [origin: $isOrigin] into ${targetFile.absolutePath}"
            )
            val inputStream = contentResolver.openInputStream(uri)
            val outputStream = FileOutputStream(targetFile)
            outputStream.use { os ->
                inputStream?.use { it.copyTo(os) }
            }
        } catch (e: Exception) {
            LogUtils.error("Caching $assetId [origin: $isOrigin] error", e)
            throw e
        }
        return targetFile
    }

    private fun getCacheFile(context: Context, assetEntity: AssetEntity, isOrigin: Boolean): File {
        val originString = if (isOrigin) "_o" else ""
        val name = "$FILENAME_PREFIX${assetEntity.id}${originString}_${assetEntity.displayName}"
        return File(context.cacheDir, name)
    }

    fun clearFileCache(context: Context) {
        val files = context.cacheDir?.listFiles()?.filterNotNull() ?: return
        for (file in files) {
            if (file.name.startsWith(FILENAME_PREFIX)) {
                file.delete()
            }
        }
    }
}
